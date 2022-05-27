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
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CardholderCounts_ExposedVirgin] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	UPDATE STATISTICS Staging.OfferReport_CTCustomers;

	WITH CycleDates AS (
		SELECT
			ioc.ironoffercyclesid
			, CAST(cyc.StartDate AS DATE) AS StartDate
			, CAST(cyc.EndDate AS DATE) AS EndDate
		FROM [WH_Virgin].[Report].[IronOfferCycles] ioc
		INNER JOIN [WH_Virgin].[Report].[OfferCycles] cyc
			ON ioc.offercyclesid = cyc.OfferCyclesID
	)
	-- Warehouse Exposed
    SELECT
	   ct.GroupID
	   , ct.Exposed
	   , COUNT(DISTINCT(ct.FanID)) Cardholders
	   , ct.isWarehouse
    FROM Staging.OfferReport_CTCustomers ct
	INNER JOIN CycleDates cyc
		ON ct.GroupID = cyc.ironoffercyclesid
	INNER JOIN [WH_Virgin].[Derived].[Customer] cu
		ON ct.FanID = cu.FanID
		AND cu.CurrentlyActive = 1
	WHERE
		ct.IsVirgin = 1
		AND ct.Exposed = 1
    GROUP BY
		GroupID
		, Exposed
		, ct.isWarehouse

	UNION ALL

	-- Control (all)
	SELECT
	   ct.GroupID
	   , ct.Exposed
	   , COUNT(1) Cardholders
	   , ct.isWarehouse -- 2.0
    FROM Staging.OfferReport_CTCustomers ct
	WHERE NOT (
		ct.IsVirgin = 1
		AND ct.Exposed = 1
	)
    GROUP BY
		GroupID
		, Exposed
		, ct.isWarehouse
	OPTION (FORCE ORDER, RECOMPILE);
	
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