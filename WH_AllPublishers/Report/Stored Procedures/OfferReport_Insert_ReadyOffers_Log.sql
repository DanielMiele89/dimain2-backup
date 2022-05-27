
/******************************************************************************
PROCESS NAME: Offer Calculation - Insert Ready Offers

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Inserts the offers for Offer and Monthly reporting that were live 
		  and are also available for reporting into the log table so they are
		  accessible by the OfferCalculation package

		  Live - An offer that was running at any part during the reporting month
			 (only applicable to Monthly reports)
		  Available - An offer that ended after a specified time (2 weeks)
			 For monthly reporting this is the end of the offer or if this
			 falls outside of the month, 2 weeks at the end of the reporting month
	  
Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Added ControlGroupTypeID to handle multiple control groups
    - Added IronOfferCyclesID to handle multiple segments

25/08/2017 Hayden Reid
    - Added logic to update Monthly Date for offers that are contained within a 
	   month regardless of the current monthly reports that are due

14/05/2018 Jason Shipp
	- Added logic to fetch offer partials for the end of a month. Update 16/07/2018: Moved logic from a UNION to a new INSERT to allow for a duplication check 

17/05/2018 Jason Shipp
	- Removed check against already-existing data by IronOfferCyclesID
	- Stops duplication where calculation dates are the same for the same Iron Offer ID, but different IronOfferCyclesIDs have been created 

10/07/2018 Jason Shipp
	- Paramatised days lag to wait between offers ending and offers being picked up for calculation

17/12/2018 Jason Shipp
	- Fixed logic to fetch offer partials for the end of a month: stopped duplications occurring when using current logic

06/02/2019 Jason Shipp
	- Created separate Campaign and Monthly parameters for days lag to wait between offers ending and offers being picked up for calculation
	- Fixed logic to fetch offer partials for the end of a month: Allowed for cases where an offer has no activity between two activity periods (so no in-between partials needed)

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Insert_ReadyOffers_Log] 
AS
BEGIN

    SET NOCOUNT ON

	DECLARE @DaysAgoOffersEndedCampaign int = 6; -- All offers that have ended @DaysAgoOffersEndedCampaign days prior (default to 13)
	DECLARE @DaysAgoOffersEndedMonthly int = 6; -- All Monthly periods that have ended @DaysAgoOffersEndedMonthly days prior (default to 13)

    -- Assuming that transactions will be recieved up to 2 weeks after the end of the offer, calculate the month to perform calculation for:
    -- After 2 weeks into the month, assume that the current monthly report (i.e. the previous month) has been completed and start calculating for the next report

	DECLARE @MonthStartDateInt INT
		,	@MonthStartDate DATETIME2(7)
	
	EXEC @MonthStartDateInt = [Report].[MonthStartDate_Fetch]	-- If adjusting adjustments late for Monthly Reports, manually set this to the first of the relevant month
	SET @MonthStartDate = (SELECT CONVERT(DATETIME, CONVERT(CHAR(8), CAST(CONVERT(CHAR(8), @MonthStartDateInt, 112) AS INT))))

    DECLARE @MonthEndDate DATETIME2(7) = DATEADD(MS, -1, DATEADD(D, 1, CONVERT(DATETIME2, EOMONTH(@MonthStartDate))));

    IF OBJECT_ID('tempdb..#AllOffers') IS NOT NULL DROP TABLE #AllOffers;

	CREATE TABLE #AllOffers (	OfferID INT
							,	IronOfferID INT
							,	OfferReportingPeriodsID INT
							,	StartDate DATETIME2(7)
							,	EndDate DATETIME2(7)
							,	IsPartial BIT
							,	OfferStartDate DATETIME2(7)
							,	OfferEndDate DATETIME2(7)
							,	ReportingDate DATETIME2(7));

	INSERT INTO #AllOffers	-- Get available full offers that do not have a row in the log table
    SELECT	DISTINCT
			orp.OfferID
		,	orp.IronOfferID
		,	orp.OfferReportingPeriodsID
		,	orp.StartDate -- 2.0
		,	orp.EndDate -- 2.0
	--	,	orp.ControlGroupTypeID -- 2.0
		,	0 isPartial
		,	OfferStartDate = o.StartDate
		,	OfferEndDate = o.EndDate
		,	ReportingDate = CAST(NULL as Date)
    FROM [Report].[OfferReport_OfferReportingPeriods] orp
	INNER JOIN [Derived].[Offer] o
		ON orp.OfferID = o.OfferID
    WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_Log] ol
						WHERE ol.IronOfferID = orp.IronOfferID
						AND ol.StartDate = orp.StartDate
						AND ol.EndDate = orp.EndDate
					--	AND ol.ControlGroupTypeID = ior.ControlGroupTypeID -- 2.0 Added ControlGroupTypeID	--	RF 20211108
						and ol.StartDate = orp.StartDate
						and ol.EndDate = orp.EndDate
						and ol.isPartial = 0)
	AND NOT EXISTS (SELECT 1
					FROM [Report].[OfferReport_PublisherExclude] pe
					WHERE pe.RetailerID = orp.RetailerID
					AND orp.StartDate between pe.StartDate and pe.EndDate
					AND orp.PublisherID = pe.PublisherID)
	AND o.StartDate <= GETDATE() - @DaysAgoOffersEndedCampaign -- All offers that have ended @DaysAgoOffersEndedCampaign days prior
	AND orp.PartnerID NOT IN (4523,4578,4590,4591,4593,4594,4595,4596,4605,4608);

    INSERT INTO #AllOffers    
    SELECT	orp.OfferID	--	Get all offers that are partial and not in log table
		,	orp.IronOfferID
		,	orp.OfferReportingPeriodsID
		,	orp.StartDate -- 2.0
		,	orp.EndDate -- 2.0
	--	,	orp.ControlGroupTypeID -- 2.0
		,	orp.isPartial
		,	orp.offerStartDate
		,	orp.offerEndDate
		,	orp.ReportingDate
    FROM (	SELECT	DISTINCT
					orp.PublisherID
				,	orp.RetailerID
				,	orp.PartnerID
				,	orp.OfferID
				,	orp.IronOfferID
				,	orp.OfferReportingPeriodsID
				,	CASE WHEN orp.StartDate < @MonthStartDate THEN @MonthStartDate ELSE orp.StartDate END StartDate -- Set Start Date to be month boundary or start date (whichever is latest)
				,	CASE WHEN orp.EndDate > @MonthEndDate THEN @MonthEndDate ELSE orp.EndDate END EndDate-- Set End Date to be month boundary or end date (whichever is earliest)
			--	,	ior.ControlGroupTypeID
				,	1 isPartial
				,	OfferStartDate = o.StartDate
				,	OfferEndDate = o.EndDate
				,	ReportingDate = NULL
			FROM [Report].[OfferReport_OfferReportingPeriods] orp
			INNER JOIN [Derived].[Offer] o
				ON orp.OfferID = o.OfferID) orp
    WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_Log] ol
						WHERE orp.OfferID = ol.OfferID
						AND orp.StartDate = ol.StartDate
						AND orp.EndDate = ol.EndDate
					--	AND ol.ControlGroupTypeID = ior.ControlGroupTypeID -- 2.0
						)
	AND NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_PublisherExclude] pe
						WHERE orp.PublisherID = pe.PublisherID
						AND pe.RetailerID = orp.RetailerID
						AND orp.StartDate BETWEEN pe.StartDate and pe.EndDate)
	AND NOT EXISTS (	SELECT 1
						FROM #AllOffers ao
						WHERE ao.OfferID = orp.OfferID
						AND ao.StartDate = orp.StartDate
						AND ao.EndDate = orp.EndDate
					--	AND ao.ControlGroupTypeID = orp.ControlGroupTypeID -- 2.0
						)
	AND (orp.OfferStartDate <= @MonthEndDate AND orp.OfferEndDate >= @MonthStartDate) --  All campaigns that are live in the month
	AND (CASE WHEN orp.EndDate > @MonthEndDate THEN @MonthEndDate ELSE orp.EndDate END <= GETDATE() - @DaysAgoOffersEndedMonthly) -- And the end of the offer or End of Month is @DaysAgoOffersEndedMonthly days prior
	AND PartnerID NOT IN (4523,4578,4590,4591,4593,4594,4595,4596,4605,4608);

	INSERT INTO #AllOffers	--	Logic to include partials at the end of a month, if not already present in #AllOffers
    SELECT	orp.OfferID
		,	orp.IronOfferID
		,	orp.OfferReportingPeriodsID
		,	orp.StartDate
		,	orp.EndDate
	--	,	orp.ControlGroupTypeID -- 2.0
		,	orp.isPartial
		,	orp.OfferStartDate
		,	orp.OfferEndDate
		,	orp.ReportingDate
    FROM (	SELECT	DISTINCT
					orp.PublisherID
				,	orp.RetailerID
				,	orp.PartnerID
				,	orp.OfferID
				,	orp.IronOfferID
				,	orp.OfferReportingPeriodsID
				,	DATEADD(DAY, 1, orp.EndDate) StartDate 
				,	CASE WHEN (o.EndDate IS NULL OR o.EndDate > @MonthEndDate) THEN @MonthEndDate ELSE o.EndDate END EndDate
			--	,	orp.ControlGroupTypeID
				,	1 isPartial
				,	OfferStartDate = o.StartDate
				,	OfferEndDate = o.EndDate
				,	NULL ReportingDate
			FROM [Report].[OfferReport_OfferReportingPeriods] orp
			INNER JOIN [Derived].[Offer] o
				ON orp.OfferID = o.OfferID
			WHERE orp.EndDate < @MonthEndDate -- Analysis end date before moth-end
			AND (o.EndDate IS NULL OR o.EndDate > orp.EndDate) -- Offer active beyond analysis end date
			AND (orp.Startdate <= @MonthEndDate AND orp.EndDate >= @MonthStartDate)) orp -- Offer live in month
    WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_Log] ol
						WHERE ol.OfferID = orp.OfferID
					--	AND ol.ControlGroupTypeID = orp.ControlGroupTypeID -- 2.0
						AND ol.EndDate >= orp.EndDate) -- Check if a partial already exists in the log table with a later end date than being fetched here
    AND NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_PublisherExclude] pe
						WHERE pe.RetailerID = orp.RetailerID
						AND orp.StartDate BETWEEN pe.StartDate and pe.EndDate
						AND orp.PublisherID = pe.PublisherID)
    AND NOT EXISTS (	SELECT 1
						FROM #AllOffers ao
						WHERE ao.OfferID = orp.OfferID
					--	AND x.ControlGroupTypeID = ior.ControlGroupTypeID -- 2.0
						AND ao.EndDate >= orp.EndDate) -- Check if a partial already exists in the staging table with a later end date than being fetched here 
	AND (orp.OfferStartDate <= @MonthEndDate AND orp.OfferEndDate >= @MonthStartDate) --  All campaigns that are live in the month
	AND (CASE WHEN orp.OfferEndDate > @MonthEndDate THEN @MonthEndDate ELSE orp.EndDate END <= GETDATE() - @DaysAgoOffersEndedMonthly) -- And the end of the offer or End of Month is @DaysAgoOffersEndedMonthly days prior
	AND PartnerID NOT IN (4523,4578,4590,4591,4593,4594,4595,4596,4605,4608)
	AND NOT EXISTS (	SELECT	1
						FROM #AllOffers ao
						WHERE orp.IronOfferID = ao.IronOfferID
					--	AND orp.ControlGroupTypeID = x.ControlGroupTypeID
						AND orp.StartDate = ao.StartDate);

    -- Calculate which offers are able to be used in a monthly report and mark with the start of the reporting month
    UPDATE #AllOffers
    SET ReportingDate = @MonthStartDate
    WHERE StartDate >= @MonthStartDate
	AND EndDate <= @MonthEndDate;

    UPDATE #AllOffers
    SET ReportingDate = DATEADD(DAY, 1, EOMONTH(StartDate, -1))
    WHERE EOMONTH(StartDate) = EOMONTH(EndDate);

    -- Insert offers into log table to be picked up for calculation
    INSERT INTO [Report].[OfferReport_Log] (OfferID, IronOfferID, OfferReportingPeriodsID, ControlGroupTypeID, StartDate, EndDate, isPartial, MonthlyReportingDate, offerStartDate, offerEndDate)
    SELECT	DISTINCT
			OfferID
		,	IronOfferID
		,	OfferReportingPeriodsID
		,	ControlGroupTypeID = 0
		,	StartDate
		,	EndDate
		,	IsPartial
		,	ReportingDate
		,	OfferStartDate
		,	OfferEndDate
    FROM #AllOffers
	ORDER BY	OfferID
			,	StartDate
			,	EndDate;


							   
	IF OBJECT_ID('tempdb..#OffersEndedEarly') IS NOT NULL DROP TABLE #OffersEndedEarly;
	SELECT	OfferID = orp1.OfferID
		,	OriginalID = orp1.ID
		,	OriginalEndDate = orp1.EndDate
		
		,	UpdatedID = orp2.ID
		,	UpdatedEndDate = orp2.EndDate
	INTO #OffersEndedEarly
	FROM [Report].[OfferReport_Log] orp1
	INNER JOIN [Report].[OfferReport_Log] orp2
		ON orp1.OfferID = orp2.OfferID
		AND orp1.IsPartial = orp2.IsPartial
		AND orp1.StartDate = orp2.StartDate
		AND orp1.EndDate > orp2.EndDate
		AND COALESCE(orp1.ErrorDetails, '') NOT LIKE '%Offer Ended Early%'

	UPDATE orl
	SET orl.IsError = 1
	,	orl.ErrorDetails =	CASE
								WHEN orl.ErrorDetails IS NULL THEN 'Offer Ended Early'
								ELSE orl.ErrorDetails + ', Offer Ended Early'
							END
	FROM [Report].[OfferReport_Log] orl
	INNER JOIN #OffersEndedEarly oee
		ON orl.ID = oee.OriginalID

							   
	IF OBJECT_ID('tempdb..#OffersExtended') IS NOT NULL DROP TABLE #OffersExtended;
	SELECT	OfferID = orp1.OfferID
		,	OriginalID = orp1.ID
		,	OriginalEndDate = orp1.EndDate
		
		,	UpdatedID = orp2.ID
		,	UpdatedEndDate = orp2.EndDate
	INTO #OffersExtended
	FROM [Report].[OfferReport_Log] orp1
	INNER JOIN [Report].[OfferReport_Log] orp2
		ON orp1.OfferID = orp2.OfferID
		AND orp1.IsPartial = orp2.IsPartial
		AND orp1.StartDate = orp2.StartDate
		AND orp1.EndDate < orp2.EndDate
		AND COALESCE(orp1.ErrorDetails, '') NOT LIKE '%Offer Ended Early%'
		AND COALESCE(orp2.ErrorDetails, '') NOT LIKE '%Offer Ended Early%'


	
END