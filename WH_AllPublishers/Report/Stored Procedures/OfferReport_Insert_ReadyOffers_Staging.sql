
/******************************************************************************
PROCESS NAME: Offer Calculation - Fetch Ready Offers
PID: OC-002

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Inserts into staging table offers for Offer and Monthly reporting that 
		  are to be calculated from the log table.

		  Live - An offer that was running at any part during the reporting month
			 (only applicable to Monthly reports)
		  Available - An offer that ended after a specified time (2 weeks)
			 For monthly reporting this is the end of the offer or if this
			 falls outside of the month, 2 weeks at the end of the reporting month

		- @IronOfferIDList is a list of IronOffers, separated by commas or new lines, all in one string
	  
Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Added ControlGroupID in INSERT query
    - Added join logic for OfferReportingPeriodsID (multiple segments) and ControlGroupTypeID (multiple controlgroups)

Jason Shipp 16/04/2019
	- Added logic to identify AMEX type publishers by a ClubID <0

Jason Shipp 23/04/2020
	- Added parameterisation to allow control of whether to include Campaign and/or Monthly analysis periods and whether to include AMEX

Jason Shipp 04/05/2020
	- Added parameterisation control whether to include a bespoke list of IronOfferIDs

******************************************************************************/

CREATE PROCEDURE [Report].[OfferReport_Insert_ReadyOffers_Staging] (	@IncludeCampaignCalcs BIT
																,	@IncludeMonthlyCalcs BIT
																,	@IncludeAMEX BIT
																,	@IncludeOnlyAMEX BIT
																,	@FlashReportRetailersOnly BIT
																,	@IronOfferIDList VARCHAR(MAX))
AS
BEGIN

    SET NOCOUNT ON
	
	------ For testing
	--DECLARE @IncludeCampaignCalcs bit = 1;
	--DECLARE @IncludeMonthlyCalcs bit = 0;
	--DECLARE @IncludeAMEX bit = 1;
	--DECLARE @IncludeOnlyAMEX bit = 0;
	--DECLARE @FlashReportRetailersOnly bit = 0;
	--DECLARE @IronOfferIDList varchar(max) = '';
	
	DECLARE @MonthStartDateInt INT
		,	@MonthStartDate DATETIME2(7)
	
	EXEC @MonthStartDateInt = [Report].[MonthStartDate_Fetch]	-- If adjusting adjustments late for Monthly Reports, manually set this to the first of the relevant month
	SET @MonthStartDate = (SELECT CONVERT(DATETIME, CONVERT(CHAR(8), CAST(CONVERT(CHAR(8), @MonthStartDateInt, 112) AS INT))))
	
	DECLARE @Today DATETIME2(7) = (CAST(GETDATE() AS date));

--	DECLARE @ExpAMEXCompletenessDate date = DATEFROMPARTS(YEAR(@MonthStartDate), MONTH(@MonthStartDate), 22);


	-- Remove new lines from Iron Offer list (if applicable) and spaces after commas
	SET @IronOfferIDList = REPLACE(REPLACE(@IronOfferIDList, CHAR(13) + CHAR(10), ','), ', ', ',');

	TRUNCATE TABLE [Report].[OfferReport_AllOffers];

	-- Get list of offers that have not been calculated or had an error for out of programme control groups

	INSERT INTO [Report].[OfferReport_AllOffers]
	SELECT	orl.OfferID
		,	orl.IronOfferID
		,	MAX(orp.OfferReportingPeriodsID) AS OfferReportingPeriodsID
		,	MAX(COALESCE(orp.ControlGroupID_InProgramme, orp.ControlGroupID_OutOfProgramme)) AS ControlGroupID
		,	IsInPromgrammeControlGroup = CASE WHEN orp.ControlGroupID_InProgramme IS NOT NULL THEN 1 ELSE 0 END
		,	orl.StartDate
		,	orl.EndDate
		,	orp.PartnerID
		,	orp.SpendStretch
		,	orl.isPartial
		,	orl.MonthlyReportingDate 
		,	orp.PublisherID
		,	orp.StartDate offerStartDate
		,	orp.EndDate offerEndDate
		,	pa.BrandID
	FROM [Report].[OfferReport_Log] orl
	INNER JOIN [Report].[OfferReport_OfferReportingPeriods] orp
		ON orp.OfferID = orl.OfferID
		AND orp.OfferReportingPeriodsID = orl.OfferReportingPeriodsID
		AND orp.ControlGroupID_OutOfProgramme IS NOT NULL
	--	AND orp.ControlGroupTypeID = orl.ControlGroupTypeID -- 2.0
	--	AND orp.StartDate = orl.OfferStartDate
	--	AND orp.EndDate = orl.OfferEndDate
	INNER JOIN [Derived].[Partner] pa
		ON orp.PartnerID = pa.PartnerID
	WHERE orl.isCalculated = 0
	AND orl.isError = 0
	AND NOT EXISTS (SELECT 1
					FROM [Report].[OfferReport_Results] orr
					WHERE orr.OfferID = orl.OfferID
					AND orr.StartDate = orl.StartDate
					AND orr.EndDate = orl.EndDate
					AND orr.OfferReportingPeriodsID = orl.OfferReportingPeriodsID)
	AND NOT EXISTS (SELECT 1
					FROM [Report].[OfferReport_AllOffers] ao
					WHERE orl.OfferID = ao.OfferID
					AND orl.StartDate = ao.StartDate
					AND orl.EndDate = ao.EndDate
					AND orp.ControlGroupID_OutOfProgramme = ao.ControlGroupID)
	
	AND ((	@IncludeCampaignCalcs = 1 AND orl.isPartial = 0) -- Control Campaign analysis periods
		OR (@IncludeMonthlyCalcs = 1 AND orl.MonthlyReportingDate <= @MonthStartDate)) -- Control Monthly analysis periods
	
	AND ((@IncludeAMEX = 0 AND orp.PublisherID != 2001) OR @IncludeAMEX = 1) -- Control whether to include AMEX
	
	AND ((@IncludeOnlyAMEX = 1 AND orp.PublisherID = 2001) OR @IncludeOnlyAMEX = 0) -- Control whether to only include AMEX. Ensure AMEX data is complete
	
	AND (	LEN(@IronOfferIDList) = 0	--	Control whether to include a bespoke list of IronOfferIDs
		OR	LEN(@IronOfferIDList) IS NULL 
		OR	(LEN(@IronOfferIDList) >0 AND CHARINDEX(',' + CAST(orl.IronOfferID AS varchar) + ',', ',' + @IronOfferIDList + ',') > 0))

	GROUP BY	orl.IronOfferID
			,	orl.OfferID
			,	CASE WHEN orp.ControlGroupID_InProgramme IS NOT NULL THEN 1 ELSE 0 END
			,	orl.StartDate
			,	orl.EndDate
			,	orp.PartnerID
			,	orp.SpendStretch
			,	orl.isPartial
			,	orl.MonthlyReportingDate 
			,	orp.PublisherID
			,	orp.StartDate
			,	orp.EndDate
			,	pa.BrandID;

	---- Get list of offers that have not been calculated or had an error for in programme control groups

	--INSERT INTO [Report].[OfferReport_AllOffers]
	--SELECT	orl.OfferID
	--	,	orl.IronOfferID
	--	,	MAX(orp.OfferReportingPeriodsID) AS OfferReportingPeriodsID
	--	,	MAX(orp.ControlGroupID_InProgramme) AS ControlGroupID
	--	,	IsInPromgrammeControlGroup = 1
	--	,	orl.StartDate
	--	,	orl.EndDate
	--	,	orp.PartnerID
	--	,	orp.SpendStretch
	--	,	orl.isPartial
	--	,	orl.MonthlyReportingDate 
	--	,	orp.PublisherID
	--	,	orp.StartDate offerStartDate
	--	,	orp.EndDate offerEndDate
	--	,	pa.BrandID
	--FROM [Report].[OfferReport_Log] orl
	--INNER JOIN [Report].[OfferReport_OfferReportingPeriods] orp
	--	ON orp.OfferID = orl.OfferID
	--	AND orp.OfferReportingPeriodsID = orl.OfferReportingPeriodsID
	--	AND orp.ControlGroupID_InProgramme IS NOT NULL
	----	AND orp.ControlGroupTypeID = orl.ControlGroupTypeID -- 2.0
	----	AND orp.StartDate = orl.OfferStartDate
	----	AND orp.EndDate = orl.OfferEndDate
	--INNER JOIN [Derived].[Partner] pa
	--	ON orp.PartnerID = pa.PartnerID
	--WHERE orl.isCalculated = 0
	--AND orl.isError = 0
	--AND NOT EXISTS (SELECT 1
	--				FROM [Report].[OfferReport_Results] orr
	--				WHERE orr.OfferID = orl.OfferID
	--				AND orr.StartDate = orl.StartDate
	--				AND orr.EndDate = orl.EndDate
	--				AND orr.OfferReportingPeriodsID = orl.OfferReportingPeriodsID
	--				AND orr.IsInPromgrammeControlGroup = 1)
	--AND NOT EXISTS (SELECT 1
	--				FROM [Report].[OfferReport_AllOffers] ao
	--				WHERE orl.OfferID = ao.OfferID
	--				AND orl.StartDate = ao.StartDate
	--				AND orl.EndDate = ao.EndDate
	--				AND orp.ControlGroupID_OutOfProgramme = ao.ControlGroupID
	--				AND ao.IsInPromgrammeControlGroup = 1)
	
	--AND ((	@IncludeCampaignCalcs = 1 AND orl.isPartial = 0) -- Control Campaign analysis periods
	--	OR (@IncludeMonthlyCalcs = 1 AND orl.MonthlyReportingDate <= @MonthStartDate)) -- Control Monthly analysis periods
	
	--AND ((@IncludeAMEX = 0 AND orp.PublisherID != 2001) OR @IncludeAMEX = 1) -- Control whether to include AMEX
	
	--AND ((@IncludeOnlyAMEX = 1 AND orp.PublisherID = 2001) OR @IncludeOnlyAMEX = 0) -- Control whether to only include AMEX. Ensure AMEX data is complete
	
	--AND (	LEN(@IronOfferIDList) = 0	--	Control whether to include a bespoke list of IronOfferIDs
	--	OR	LEN(@IronOfferIDList) IS NULL 
	--	OR	(LEN(@IronOfferIDList) > 0 AND CHARINDEX(',' + CAST(orl.IronOfferID AS varchar) + ',', ',' + @IronOfferIDList + ',') > 0))

	--GROUP BY	orl.IronOfferID
	--		,	orl.OfferID
	--		,	orl.StartDate
	--		,	orl.EndDate
	--		,	orp.PartnerID
	--		,	orp.SpendStretch
	--		,	orl.isPartial
	--		,	orl.MonthlyReportingDate 
	--		,	orp.PublisherID
	--		,	orp.StartDate
	--		,	orp.EndDate
	--		,	pa.BrandID;
		
	-- If running for Flash Report Retailers only, then remove all other retailer offers

		IF @FlashReportRetailersOnly = 1
			BEGIN

				DELETE ao
				FROM [Report].[OfferReport_AllOffers] ao
				WHERE NOT EXISTS (	SELECT 1
									FROM [Report].[ControlSetup_FlashReportRetailers] frr
									WHERE ao.PartnerID = frr.RetailerID)

			END
		
	-- If there are Amex offers included but we have not yet had Amex data fully populated for the reporting period then remove them

		DECLARE @LatestAmexTranDate DATE;

		SELECT	@LatestAmexTranDate = MAX(TransactionDate)
		FROM [SLC_Report].[ras].[PANless_Transaction] pt
		WHERE EXISTS (	SELECT 1
						FROM [SLC_REPL].[dbo].[CRT_File] crt
						WHERE pt.FileID = crt.ID
						AND crt.VectorID = 44)

		DELETE ao
		FROM [Report].[OfferReport_AllOffers] ao
		WHERE PublisherID = 2001
		AND ao.EndDate > @LatestAmexTranDate

	-- Error offers that have already been calculated
	
		UPDATE ol
		SET ErrorDetails = 'Already calculated'
		,	isError = 1
		,	ModifiedDate = GETDATE()
		FROM [Report].[OfferReport_AllOffers] l
		INNER JOIN [Report].[OfferReport_Log] ol 
			ON ol.OfferID = l.OfferID
			AND ol.OfferReportingPeriodsID = l.OfferReportingPeriodsID
			AND ol.StartDate = l.StartDate
			AND ol.EndDate = l.EndDate
		INNER JOIN [Report].[OfferReport_Results] r
			ON r.OfferID = ol.OfferID
			AND r.StartDate = ol.StartDate
			AND r.EndDate = ol.EndDate
			AND r.OfferReportingPeriodsID = ol.OfferReportingPeriodsID
			AND r.ControlGroupID = l.ControlGroupID -- 2.0

    -- Log errors
	
		INSERT INTO [Report].[OfferReport_Log_Errors]
		SELECT	l.ID 
			,	ErrorDetails
			,	GETDATE()
		FROM [Report].[OfferReport_AllOffers] l
		INNER JOIN [Report].[OfferReport_Log] ol 
			ON ol.OfferID = l.OfferID
			AND ol.OfferReportingPeriodsID = l.OfferReportingPeriodsID
			AND ol.StartDate = l.StartDate
			AND ol.EndDate = l.EndDate
			AND isError = 1

    -- Update log table calc date for offers

		--UPDATE ol
		--SET CalcDate = GETDATE()
		--FROM [Report].[OfferReport_AllOffers] l
		--JOIN [Report].[OfferReport_Log] ol
		--	ON ol.IronOfferID = l.IronOfferID
		--	AND (
		--		ol.OfferReportingPeriodsID = l.OfferReportingPeriodsID
		--		OR ol.OfferReportingPeriodsID IS NULL AND l.OfferReportingPeriodsID IS NULL
		--	)
		--	AND ol.ControlGroupTypeID = l.ControlGroupTypeID
		--	AND ol.StartDate = l.StartDate
		--	AND ol.EndDate = l.EndDate
		--WHERE NOT EXISTS (
		--	SELECT 1 FROM [Report].[OfferReport_Results] r
		--	WHERE r.IronOfferID = l.IronOfferID
		--	AND (
		--		r.OfferReportingPeriodsID = l.OfferReportingPeriodsID
		--		OR r.OfferReportingPeriodsID IS NULL AND l.OfferReportingPeriodsID IS NULL
		--	)
		--	AND r.ControlGroupTypeID = l.ControlGroupTypeID
		--	AND r.StartDate = l.StartDate
		--	AND r.EndDate = l.EndDate
		--);

END



--DELETE ao
--FROM [Report].[OfferReport_AllOffers] ao
--INNER JOIN [Derived].[Offer] o
--	ON ao.OfferID = o.OfferID
--WHERE o.RetailerID NOT IN (4036,4536,4580,4668,4713,4791,4796,4797,4798,4820,4842,4843,4849,4851,4854,4898,4899,4913,4928)

--DELETE ao
--FROM [Report].[OfferReport_AllOffers] ao
--INNER JOIN [Derived].[Offer] o
--	ON ao.OfferID = o.OfferID
--WHERE o.RetailerID IN (4851,4798,4820,4796,4536,4899,4854,4913,4713,4797)
