﻿/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the transactions for Warehouse Mailed, Control and nfi Control customers

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

03/01/2017  Hayden Reid
    - Added UNION for AMEX offers.  When AMEX becomes an official publisher, this union will need to be changed to account for it.

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Changed logic from PublisherID to [isWarehouse]
    - Removed PublisherExclude
	   - Prevented the possibility of creating a distinct customer group however,
	   on further inspection, if an offer is excluded at the point of input, this table is
	   not required for further filtering

22/10/2018 Jason Shipp 
	- Changed logic to count distinct transactions when calculating AllTransThreshold, and removed unnecessary join to [Staging].[OfferReport_ConsumerTransaction]

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CTMetrics_Threshold_V2_20210816] (@ID INT)
	
AS
BEGIN
		
	   SET NOCOUNT ON
	
	--	DECLARE @ID INT = 714

		IF OBJECT_ID('tempdb..#OfferReport_AllOffers') IS NOT NULL DROP TABLE #OfferReport_AllOffers
		SELECT *
		INTO #OfferReport_AllOffers
		FROM Staging.OfferReport_AllOffers o -- 2.0
		WHERE o.ID = @ID
		
		CREATE CLUSTERED INDEX CIX_CID ON #OfferReport_AllOffers (IronOfferID)


		IF OBJECT_ID('tempdb..#OfferReport_CTCustomers') IS NOT NULL DROP TABLE #OfferReport_CTCustomers
		SELECT	*
			,	COALESCE(cu.CINID_Warehouse, cu.CINID_Virgin) AS CINID
		INTO #OfferReport_CTCustomers
		FROM Staging.OfferReport_CTCustomers cu
		WHERE cu.Exposed = 0
		AND EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers o
						WHERE cu.GroupID = o.ControlGroupID
						AND cu.IsVirgin = o.IsVirgin
						AND cu.IsWarehouse = o.IsWarehouse)

		INSERT INTO #OfferReport_CTCustomers
		SELECT	*
			,	COALESCE(cu.CINID_Warehouse, cu.CINID_Virgin) AS CINID
		FROM Staging.OfferReport_CTCustomers cu
		WHERE cu.Exposed = 1
		AND EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers o
						WHERE cu.GroupID = o.IronOfferCyclesID
						AND cu.IsVirgin = o.IsVirgin
						AND cu.IsWarehouse = o.IsWarehouse)
						
		CREATE CLUSTERED INDEX CIX_CID ON #OfferReport_CTCustomers (CINID, Exposed)
		CREATE NONCLUSTERED INDEX IX_CINDateAmount_IncCCID ON #OfferReport_CTCustomers (Exposed) INCLUDE (GroupID, IsWarehouse, IsVirgin, CINID)
		CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferReport_CTCustomers (GroupID, Exposed, IsWarehouse, IsVirgin, CINID)

		IF OBJECT_ID('tempdb..#OfferReport_ConsumerCombinations') IS NOT NULL DROP TABLE #OfferReport_ConsumerCombinations
		SELECT *
		INTO #OfferReport_ConsumerCombinations
		FROM Staging.OfferReport_ConsumerCombinations cc
		WHERE EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers o
						WHERE cc.PartnerID = o.PartnerID
						AND cc.IsVirgin = o.IsVirgin
						AND cc.IsWarehouse = o.IsWarehouse)

		CREATE CLUSTERED INDEX CIX_CCID ON #OfferReport_ConsumerCombinations (ConsumerCombinationID)
		CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferReport_ConsumerCombinations (PartnerID, IsWarehouse, IsVirgin, ConsumerCombinationID)

		IF OBJECT_ID('tempdb..#OfferReport_ConsumerTransaction') IS NOT NULL DROP TABLE #OfferReport_ConsumerTransaction
		SELECT *
		INTO #OfferReport_ConsumerTransaction
		FROM Staging.OfferReport_ConsumerTransaction ct
		WHERE EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers ao
						WHERE ct.TranDate BETWEEN ao.StartDate and ao.EndDate
						AND ct.IsVirgin = ao.IsVirgin
						AND ct.IsWarehouse = ao.IsWarehouse)
		AND EXISTS (	SELECT 1
						FROM #OfferReport_ConsumerCombinations cc
						WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)
		AND EXISTS (	SELECT 1
						FROM #OfferReport_CTCustomers cu
						WHERE ct.CINID = cu.CINID)
						
		CREATE CLUSTERED INDEX CIX_CCID ON #OfferReport_ConsumerTransaction (ConsumerCombinationID)
		CREATE NONCLUSTERED INDEX IX_All ON #OfferReport_ConsumerTransaction ([IsWarehouse],[IsVirgin],[TranDate],[Amount]) INCLUDE ([ConsumerCombinationID],[CINID])
		CREATE NONCLUSTERED INDEX IX_All2 ON #OfferReport_ConsumerTransaction ([IsWarehouse],[IsVirgin],[TranDate],[Amount]) INCLUDE ([ConsumerCombinationID],[CINID],[IsOnline])
		CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferReport_ConsumerTransaction (TranDate, IsWarehouse, IsVirgin, ConsumerCombinationID, CINID, IsOnline)
		

		IF OBJECT_ID('tempdb..#OfferReport_ThresholdMetrics') IS NOT NULL DROP TABLE #OfferReport_ThresholdMetrics
		SELECT *
		INTO #OfferReport_ThresholdMetrics
		FROM [Staging].[OfferReport_ThresholdMetrics] tm
		WHERE EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers ao
						WHERE tm.IronOfferID = ao.IronOfferID
						AND tm.ControlGroupID = ao.ControlGroupID
						AND tm.StartDate = ao.StartDate
						AND tm.EndDate = ao.EndDate
						AND tm.IsWarehouse = ao.isWarehouse
						AND tm.IsVirgin = ao.IsVirgin
						AND (	tm.IronOfferCyclesID = ao.IronOfferCyclesID
							OR (tm.IronOfferCyclesID IS NULL AND ao.IronOfferCyclesID IS NULL)))
							
		
		CREATE CLUSTERED INDEX CIX_OFferCG ON #OfferReport_ThresholdMetrics (IronOfferID, ControlGroupID, IronOfferCyclesID)




    -- Main Results - Get Total Level
		IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
		SELECT	o.IronOfferID
		   ,	o.IronOfferCyclesID
		   ,	o.ControlGroupTypeID
		   ,	o.StartDate
		   ,	o.EndDate
		   ,	NULL Channel
		   ,	SUM(ct.Amount) Sales
		   ,	NULL Trans
		   ,	COUNT(1) ThresholdTrans
		   ,	COUNT(DISTINCT ct.CINID) as Spenders
		   ,	NULL Threshold
		   ,	c.Exposed
		   ,	o.offerStartDate
		   ,	o.offerEndDate
		   ,	o.PartnerID
		   ,	c.IsWarehouse -- 2.0
		   ,	c.IsVirgin -- 2.0
		INTO #Results
		FROM #OfferReport_AllOffers o -- 2.0
		JOIN #OfferReport_CTCustomers c 
			ON ((	c.GroupID = o.ControlGroupID AND Exposed = 0)
				OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1))
			AND c.IsWarehouse = o.IsWarehouse
			AND c.IsVirgin = o.IsVirgin
		JOIN #OfferReport_ConsumerCombinations cc 
		   ON cc.PartnerID = o.PartnerID
			AND cc.IsWarehouse = o.IsWarehouse
			AND cc.IsVirgin = o.IsVirgin
		JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
		   ON oe.PartnerID = o.PartnerID
		   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
		JOIN #OfferReport_ConsumerTransaction ct with (nolock)
		   ON ct.CINID = c.CINID
		   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
		   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
		   AND ct.Amount > 0 and ct.Amount < oe.UpperValue
			AND ct.IsWarehouse = o.IsWarehouse
			AND ct.IsVirgin = o.IsVirgin
		GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.IsWarehouse, c.IsVirgin


    

    -- Main Results - Channel Level
	INSERT INTO #Results
    SELECT
	   o.IronOfferID
	   , o.IronOfferCyclesID
	   , o.ControlGroupTypeID
	   , o.StartDate
	   , o.EndDate
	   , ct.IsOnline Channel
	   , SUM(ct.Amount) Sales
	   , NULL Trans
	   , COUNT(1) ThresholdTrans
	   , COUNT(DISTINCT ct.CINID) as Spenders
	   , NULL Threshold
	   , c.Exposed
	   , o.offerStartDate
	   , o.offerEndDate
	   , o.PartnerID
	   , c.isWarehouse
	   , c.IsVirgin
    FROM #OfferReport_AllOffers o
    JOIN #OfferReport_CTCustomers c 
		ON ((	c.GroupID = o.ControlGroupID AND Exposed = 0)
			OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1))
		AND c.IsWarehouse = o.IsWarehouse
		AND c.IsVirgin = o.IsVirgin
    JOIN #OfferReport_ConsumerCombinations cc
		on cc.PartnerID = o.PartnerID
		AND cc.IsWarehouse = o.IsWarehouse
		AND cc.IsVirgin = o.IsVirgin
    JOIN Staging.OfferReport_OutlierExclusion oe 
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN #OfferReport_ConsumerTransaction ct with (nolock)
	   ON ct.CINID = c.CINID
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue
		AND ct.IsWarehouse = o.IsWarehouse
		AND ct.IsVirgin = o.IsVirgin
    GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, ct.IsOnline, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.isWarehouse, c.IsVirgin

    
	--Threshold Results
	IF EXISTS (SELECT 1 FROM #OfferReport_ThresholdMetrics)
		BEGIN

			INSERT INTO #Results
			SELECT
			   o.IronOfferID
			   , o.IronOfferCyclesID
			   , o.ControlGroupTypeID
			   , o.StartDate
			   , o.EndDate
			   , c.Channel Channel
			   , c.TotalSales Sales
			   , c.TotalTrans2 Trans
			   , c.TotalTrans ThresholdTrans
			   , COUNT(DISTINCT c.CINID) Spenders
			   , c.Threshold
			   , c.Exposed
			   , o.offerStartDate
			   , o.offerEndDate
			   , o.PartnerID
			   , c.isWarehouse -- 2.0
			   , c.IsVirgin -- 2.0
			FROM #OfferReport_AllOffers o
			JOIN #OfferReport_ConsumerCombinations cc 
			   ON cc.PartnerID = o.PartnerID
				AND cc.IsWarehouse = o.IsWarehouse
				AND cc.IsVirgin = o.IsVirgin
			JOIN Staging.OfferReport_OutlierExclusion oe 
			   ON oe.PartnerID = o.PartnerID
			   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
			JOIN (
			   SELECT *
				  , SUM(Trans) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed, c.isWarehouse, c.IsVirgin) TotalTrans
				  , SUM(Trans) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Exposed, c.isWarehouse, c.IsVirgin) TotalTrans2
				  , SUM(Sales) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed, c.isWarehouse, c.IsVirgin) TotalSales
			   FROM #OfferReport_ThresholdMetrics c
			) c
			   ON c.IronOfferID = o.IronOfferID
			   AND (
				  c.IronOfferCyclesID = o.IronOfferCyclesID
				  OR (c.IronOfferCyclesID IS NULL AND o.IronOfferCyclesID IS NULL)
			   )
			   AND c.ControlGroupID = o.ControlGroupID
			   AND c.StartDate = o.StartDate
			   AND c.EndDate = o.EndDate
			   AND c.IsWarehouse = o.isWarehouse
			   AND c.IsVirgin = o.IsVirgin
			GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, c.Channel, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.Threshold, c.TotalTrans, TotalTrans2, c.TotalSales, c.isWarehouse, c.IsVirgin
    
		END

    /** AMEX Offers **/
	   --AMEX Results - Get Total Level
	INSERT INTO #Results
    SELECT
	   o.IronOfferID
	   , o.IronOfferCyclesID
	   , o.ControlGroupTypeID
	   , o.StartDate
	   , o.EndDate
	   , NULL Channel
	   , SUM(ct.Amount) Sales
	   , NULL Trans
	   , COUNT(1) ThresholdTrans
	   , COUNT(DISTINCT ct.CINID) as Spenders
	   , NULL Threshold
	   , c.Exposed
	   , o.offerStartDate
	   , o.offerEndDate
	   , o.PartnerID
	   , c.isWarehouse -- 2.0
	   ,	c.IsVirgin
    FROM #OfferReport_AllOffers o -- 2.0
    JOIN Staging.OfferReport_CTCustomers c 
	   ON (
		  (c.GroupID = o.ControlGroupID AND Exposed = 0)
		  OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
	   ) 
	   AND c.isWarehouse IS NULL
	   AND c.IsVirgin IS NULL
	   AND o.isWarehouse IS NULL -- 2.0
	   AND o.IsVirgin IS NULL -- 2.0
    JOIN Staging.OfferReport_ConsumerCombinations cc
		on cc.PartnerID = o.PartnerID
		AND cc.IsWarehouse = 1
    JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN [Staging].[OfferReport_ConsumerTransaction] ct with (nolock)
		ON ct.CINID = COALESCE(c.CINID_Warehouse, c.CINID_Virgin)
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > ISNULL(o.SpendStretch, 0) and ct.Amount < oe.UpperValue -- ONLY TRANSACTIONS ABOVE SPEND STRETCH
    GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.isWarehouse, c.IsVirgin
	OPTION(RECOMPILE) -- Added by Jason Shipp 06/04/2018

	IF OBJECT_ID('tempdb..#OfferReport_CTCustomers') IS NOT NULL DROP TABLE #OfferReport_CTCustomers

	SELECT	IronOfferID
	   ,	IronOfferCyclesID
	   ,	ControlGroupTypeID
	   ,	StartDate
	   ,	EndDate
	   ,	Channel
	   ,	Sales
	   ,	Trans
	   ,	ThresholdTrans
	   ,	Spenders
	   ,	Threshold
	   ,	Exposed
	   ,	offerStartDate
	   ,	offerEndDate
	   ,	PartnerID
	   ,	isWarehouse -- 2.0
	   ,	IsVirgin
	FROM #Results

	

END


