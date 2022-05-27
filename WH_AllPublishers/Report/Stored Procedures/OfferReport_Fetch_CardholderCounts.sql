/******************************************************************************
PROCESS NAME: Offer Calculation - Fetch Cardholder Counts

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the cardholder counts for mailed and control for each offer

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Changed PublisherID to [isWarehouse] logic

18/06/2019 Jason Shipp
    - Added logic for Warehouse exposed customers to only include customers with an active card in the IronOfferCycle

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Fetch_CardholderCounts]
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE STATISTICS [Report].[OfferReport_CTCustomers];

	IF OBJECT_ID('tempdb..#OfferReportingPeriods') IS NOT NULL DROP TABLE #OfferReportingPeriods;
	SELECT	DISTINCT
			orp.OfferReportingPeriodsID
		,	orp.StartDate
		,	orp.EndDate
	INTO #OfferReportingPeriods
	FROM [Report].[OfferReport_OfferReportingPeriods] orp

	IF OBJECT_ID('tempdb..#ControlGroupID') IS NOT NULL DROP TABLE #ControlGroupID;
	SELECT	DISTINCT
			ControlGroupID = orp.ControlGroupID_InProgramme
		,	orp.StartDate
		,	orp.EndDate
	INTO #ControlGroupID
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	WHERE orp.ControlGroupID_InProgramme IS NOT NULL
	UNION
	SELECT	DISTINCT
			ControlGroupID = orp.ControlGroupID_OutOfProgramme
		,	orp.StartDate
		,	orp.EndDate
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	WHERE orp.ControlGroupID_OutOfProgramme IS NOT NULL


	IF OBJECT_ID('tempdb..#CardholderCounts') IS NOT NULL DROP TABLE #CardholderCounts
	CREATE TABLE #CardholderCounts ([GroupID] [int] NOT NULL
								,	[Exposed] [bit] NOT NULL
								,	[Cardholders] [int] NOT NULL);
    
	-- Warehouse / nFI Exposed

		INSERT INTO #CardholderCounts
		SELECT	ct.GroupID
			,	ct.Exposed
			,	Cardholders = COUNT(DISTINCT ct.FanID)
		FROM [Report].[OfferReport_CTCustomers] ct
		INNER JOIN #OfferReportingPeriods orp
			ON ct.GroupID = orp.OfferReportingPeriodsID
		INNER JOIN [SLC_REPL].[dbo].[Fan] f
			ON ct.FanID = f.ID
		WHERE ct.Exposed = 1
		AND EXISTS (SELECT 1
					FROM [Derived].[Customer] cu
					WHERE ct.FanID = cu.FanID
					AND cu.CurrentlyActive = 1
					AND (cu.PublisherType = 'nFI' OR cu.PublisherID IN (132, 138)))
		AND EXISTS (SELECT 1
					FROM [SLC_REPL].[dbo].[Pan] p -- Check for active cards
					WHERE f.CompositeID = p.CompositeID
					AND p.AdditionDate <= orp.EndDate
					AND (p.RemovalDate IS NULL OR p.RemovalDate > orp.EndDate))
		GROUP BY	GroupID
				,	Exposed;

	-- AMEX exposed

		INSERT INTO #CardholderCounts
		SELECT	orp.OfferReportingPeriodsID
			,	y.Exposed
			,	y.ClickCounts
		FROM (	SELECT	ROW_NUMBER() OVER (PARTITION BY x.IronOfferID, x.Exposed, x.isWarehouse ORDER BY x.[Priority] ASC) AS PriorityRank -- Get click-source-rank
					,	x.IronOfferID
					,	x.Exposed
					,	x.isWarehouse
					,	x.IsVirgin
					,	x.IsVisaBarclaycard
					,	x.ClickCounts
				FROM (	SELECT	ame.IronOfferID-- Priority 1: clicks received before analysis end date
							,	1 AS [Priority]
							,	cast (1 as bit) Exposed
							,	CASE WHEN (a.PartnerID = 4265 AND a.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
							,	NULL isWarehouse
							,	NULL IsVirgin 
							,	NULL IsVisaBarclaycard
							,	ROW_NUMBER() OVER (PARTITION BY a.IronOfferID, a.offerStartDate, a.offerEndDate ORDER BY ame.ReceivedDate DESC) DateRank
						FROM [Report].[OfferReport_AllOffers] a
						INNER JOIN [Report].[AmexExposedClickCounts] ame
							ON ame.IronOfferID = a.IronOfferID
							AND DATEADD(DAY, 1, ame.ReceivedDate) <= a.OfferEndDate
						WHERE ame.ClickCounts >0

						UNION

						SELECT	ame.IronOfferID-- Priority 2: clicks received as close as possible to analysis end date
							,	2 AS [Priority]
							,	CAST(1 AS bit) Exposed
							,	CASE WHEN (a.PartnerID = 4265 AND a.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
							,	NULL isWarehouse
							,	NULL IsVirgin
							,	NULL IsVisaBarclaycard
							,	ROW_NUMBER() OVER (PARTITION BY a.IronOfferID, a.offerStartDate, a.offerEndDate ORDER BY ABS(DATEDIFF(day, ame.ReceivedDate, a.OfferEndDate)) ASC) DateRank
						FROM [Report].[OfferReport_AllOffers] a
						INNER JOIN [Report].[AmexExposedClickCounts] ame
							ON ame.IronOfferID = a.IronOfferID
						WHERE ame.ClickCounts > 0) x
				WHERE x.DateRank = 1) y
		INNER JOIN [Report].[OfferReport_OfferReportingPeriods] orp
			ON y.IronOfferID = orp.IronOfferID
		WHERE y.PriorityRank = 1; -- Resolve click-source-rank
	
	-- Remaining Exposed

		INSERT INTO #CardholderCounts
		SELECT	ct.GroupID
			,	ct.Exposed
			,	Cardholders = COUNT(DISTINCT ct.FanID)
		FROM [Report].[OfferReport_CTCustomers] ct
		WHERE ct.Exposed = 1
		AND EXISTS (SELECT 1
					FROM [Derived].[Customer] cu
					WHERE ct.FanID = cu.FanID
					AND cu.CurrentlyActive = 1
					AND NOT (cu.PublisherType = 'nFI' OR cu.PublisherID IN (132, 138)))
		GROUP BY	GroupID
				,	Exposed;
	
	-- Control (all)

		INSERT INTO #CardholderCounts
		SELECT	ct.GroupID
			,	ct.Exposed
			,	Cardholders = COUNT(DISTINCT ct.FanID)
		FROM [Report].[OfferReport_CTCustomers] ct
		WHERE ct.Exposed = 0
		GROUP BY	GroupID
				,	Exposed;

	
	-- Insert to final table
	
		INSERT INTO [Report].[OfferReport_Cardholders]
		SELECT	GroupID
			,	Exposed
			,	Cardholders
		FROM #CardholderCounts cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [Report].[OfferReport_Cardholders] c
							WHERE cc.GroupID = c.GroupID
							AND cc.Exposed = c.Exposed)
	
	/******************************************************************************
	-- Old logic: exposed members instead of exposed cardholders

	SELECT
	   ct.GroupID
	   , ct.Exposed
	   , COUNT(1) Cardholders
	   , ct.isWarehouse -- 2.0
    FROM [Report].[OfferReport_CTCustomers] ct
    GROUP BY GroupID, Exposed, ct.isWarehouse;
	******************************************************************************/

END

