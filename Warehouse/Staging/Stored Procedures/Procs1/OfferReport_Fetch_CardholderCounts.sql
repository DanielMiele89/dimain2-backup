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
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CardholderCounts]
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE STATISTICS Staging.OfferReport_CTCustomers;

	IF OBJECT_ID('tempdb..#CardholderCounts') IS NOT NULL DROP TABLE #CardholderCounts;
	;WITH
	CycleDatesWarehouse AS (SELECT	ioc.IronOfferCyclesID
								,	CONVERT(DATE, cyc.StartDate) AS StartDate
								,	CONVERT(DATE, cyc.EndDate) AS EndDate
							FROM [Warehouse].[Relational].[IronOfferCycles] ioc
							INNER JOIN [Warehouse].[Relational].[OfferCycles] cyc
								ON ioc.OfferCyclesID = cyc.OfferCyclesID)

    SELECT	ct.PublisherID	-- Warehouse Exposed
		,	ct.GroupID
		,	ct.Exposed
		,	ct.IsWarehouse
		,	ct.IsVirgin
		,	ct.IsVirginPCA
		,	ct.IsVisaBarclaycard
		,	COUNT(DISTINCT(ct.FanID)) Cardholders
    INTO #CardholderCounts
	FROM [Staging].[OfferReport_CTCustomers] ct
	INNER JOIN CycleDatesWarehouse cyc
		ON ct.GroupID = cyc.IronOfferCyclesID
	INNER JOIN [SLC_REPL].[dbo].[Fan] f
		ON ct.FanID = f.ID
	WHERE ct.Exposed = 1
	AND ct.IsWarehouse = 1
	AND EXISTS (SELECT 1
				FROM [SLC_REPL].[dbo].[Pan] p -- Check for active cards
				WHERE f.CompositeID = p.CompositeID
				AND CAST(p.AdditionDate AS DATE) <= cyc.EndDate
				AND (p.RemovalDate IS NULL OR CAST(p.RemovalDate AS DATE) > cyc.EndDate))
    GROUP BY	ct.PublisherID
			,	ct.GroupID
			,	ct.Exposed
			,	ct.IsWarehouse
			,	ct.IsVirgin
			,	ct.IsVirginPCA
			,	ct.IsVisaBarclaycard;
	
    INSERT INTO #CardholderCounts	-- Virgin Exposed
	SELECT	ct.PublisherID
		,	ct.GroupID
		,	ct.Exposed
		,	ct.IsWarehouse
		,	ct.IsVirgin
		,	ct.IsVirginPCA
		,	ct.IsVisaBarclaycard
		,	COUNT(DISTINCT(ct.FanID)) Cardholders
    FROM [Staging].[OfferReport_CTCustomers] ct
	WHERE ct.Exposed = 1
	AND ct.IsVirgin = 1
	AND EXISTS (SELECT 1
				FROM [WH_Virgin].[Derived].[Customer] cu
				WHERE ct.FanID = cu.FanID
				AND cu.CurrentlyActive = 1)
    GROUP BY	ct.PublisherID
			,	ct.GroupID
			,	ct.Exposed
			,	ct.IsWarehouse
			,	ct.IsVirgin
			,	ct.IsVirginPCA
			,	ct.IsVisaBarclaycard;
	
    INSERT INTO #CardholderCounts	-- Virgin PCA Exposed
	SELECT	ct.PublisherID
		,	ct.GroupID
		,	ct.Exposed
		,	ct.IsWarehouse
		,	ct.IsVirgin
		,	ct.IsVirginPCA
		,	ct.IsVisaBarclaycard
		,	COUNT(DISTINCT(ct.FanID)) Cardholders
    FROM [Staging].[OfferReport_CTCustomers] ct
	WHERE ct.Exposed = 1
	AND ct.IsVirginPCA = 1
	AND EXISTS (SELECT 1
				FROM [WH_VirginPCA].[Derived].[Customer] cu
				WHERE ct.FanID = cu.FanID
				AND cu.CurrentlyActive = 1)
    GROUP BY	ct.PublisherID
			,	ct.GroupID
			,	ct.Exposed
			,	ct.IsWarehouse
			,	ct.IsVirgin
			,	ct.IsVirginPCA
			,	ct.IsVisaBarclaycard;
	
    INSERT INTO #CardholderCounts	-- Visa Barclaycard Exposed
	SELECT	ct.PublisherID
		,	ct.GroupID
		,	ct.Exposed
		,	ct.IsWarehouse
		,	ct.IsVirgin
		,	ct.IsVirginPCA
		,	ct.IsVisaBarclaycard
		,	COUNT(DISTINCT(ct.FanID)) Cardholders
    FROM [Staging].[OfferReport_CTCustomers] ct
	WHERE ct.Exposed = 1
	AND ct.IsVisaBarclaycard = 1
	AND EXISTS (SELECT 1
				FROM [WH_Visa].[Derived].[Customer] cu
				WHERE ct.FanID = cu.FanID
				AND cu.CurrentlyActive = 1)
    GROUP BY	ct.PublisherID
			,	ct.GroupID
			,	ct.Exposed
			,	ct.IsWarehouse
			,	ct.IsVirgin
			,	ct.IsVirginPCA
			,	ct.IsVisaBarclaycard;

    INSERT INTO #CardholderCounts	-- Control (all)
    SELECT	ct.PublisherID
		,	ct.GroupID
		,	ct.Exposed
		,	ct.IsWarehouse
		,	ct.IsVirgin
		,	ct.IsVirginPCA
		,	ct.IsVisaBarclaycard
		,	COUNT(1) Cardholders
    FROM Staging.OfferReport_CTCustomers ct
	WHERE NOT (ct.IsWarehouse = 1 AND ct.Exposed = 1)
	AND NOT (ct.IsVirgin = 1 AND ct.Exposed = 1)
	AND NOT (ct.IsVirginPCA = 1 AND ct.Exposed = 1)
	AND NOT (ct.IsVisaBarclaycard = 1 AND ct.Exposed = 1)
    GROUP BY	ct.PublisherID
			,	ct.GroupID
			,	ct.Exposed
			,	ct.IsWarehouse
			,	ct.IsVirgin
			,	ct.IsVirginPCA
			,	ct.IsVisaBarclaycard

	OPTION (FORCE ORDER, RECOMPILE);

	SELECT	PublisherID
		,	GroupID
		,	Exposed
		,	IsWarehouse
		,	IsVirgin
		,	IsVirginPCA
		,	IsVisaBarclaycard
		,	Cardholders
	FROM #CardholderCounts
	
	/******************************************************************************
	-- Old logic: exposed members instead of exposed cardholders

	SELECT
	   ct.GroupID
	   , ct.Exposed
	   , COUNT(1) Cardholders
	   , ct.isWarehouse -- 2.0
    FROM Staging.OfferReport_CTCustomers ct
    GROUP BY GroupID, Exposed, ct.isWarehouse;
	******************************************************************************/

END