/******************************************************************************
Author	  Hayden Reid
Created	  03/05/2017
Purpose	  Gets customers that spent over the spend stretch so that their transactions 
		  regardless of spend stretch can be retrieved

Copyright © 2017, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Changed logic from PublisherID to [isWarehouse]
    - Removed PublisherExclude
	   - Prevented the possibility of creating a distinct customer group however,
	   on further inspection, if an offer is excluded at the point of input, this table is
	   not required for further filtering

31/07/2017 Hayden Reid
    - Changed query for performance considerations by creating cinid - ironoffer table
	   and then joining to CT using this new table

    - Added ID parameter for SSIS loop, since the table that will be created needs a new row per cinid/ironoffer/date combo
	   this table could potentially be quite large

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ThresholdMetrics_V3_20210816] (
    @ID INT = NULL
)
AS
	   
BEGIN

	--	DECLARE @ID INT = 5
	DECLARE @Today DATETIME = GETDATE()

	IF OBJECT_ID('tempdb..#OfferReport_AllOffers') IS NOT NULL DROP TABLE #OfferReport_AllOffers
	SELECT	ao.PartnerID
		,	ao.IronOfferID
		,	ao.IronOfferCyclesID
		,	ao.ControlGroupID 
		,	ao.StartDate
		,	ao.EndDate
		,	oe.UpperValue
		,	ao.SpendStretch
		,	ao.offerStartDate
		,	ao.offerEndDate
		,	ao.isWarehouse
		,	ao.IsVirgin
	INTO #OfferReport_AllOffers
	FROM [Staging].[OfferReport_AllOffers] ao -- 2.0
	INNER JOIN [Staging].[OfferReport_OutlierExclusion] oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
          ON oe.PartnerID = ao.PartnerID
          AND ao.OfferStartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, @Today)	
     WHERE ao.SpendStretch IS NOT NULL
	 AND (ao.ID = @ID OR @ID IS NULL)

	IF OBJECT_ID('tempdb..#OfferReport_ConsumerTransaction') IS NOT NULL DROP TABLE #OfferReport_ConsumerTransaction
	SELECT	ao.PartnerID
		,	ao.IronOfferID
		,	CASE
				WHEN ct.Amount < ao.SpendStretch THEN 0
				ELSE 1
			END AS AboveSpendStretch
		,	ct.IsOnline
		,	ct.CINID
		,	ct.Amount
		,	ct.IsVirgin
		,	ct.IsWarehouse
	INTO #OfferReport_ConsumerTransaction
	FROM #OfferReport_AllOffers ao
	INNER JOIN [Staging].[OfferReport_ConsumerCombinations] cc
		ON ao.PartnerID = cc.PartnerID
	INNER JOIN [Staging].[OfferReport_ConsumerTransaction] ct
        ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
		AND ct.TranDate BETWEEN ao.StartDate AND ao.EndDate
		AND 0 < ct.Amount
		AND ct.Amount < ao.UpperValue
		AND cc.IsWarehouse = ct.IsWarehouse
		AND cc.IsVirgin = ct.IsVirgin

	CREATE CLUSTERED INDEX CIX_CINID ON #OfferReport_ConsumerTransaction (CINID)
	CREATE NONCLUSTERED INDEX IX_CINID ON #OfferReport_ConsumerTransaction (CINID, AboveSpendStretch, IsOnline)
	
	IF OBJECT_ID('tempdb..#OfferReport_CTCustomers') IS NOT NULL DROP TABLE #OfferReport_CTCustomers
	SELECT	ao.PartnerID
		,	ao.IronOfferID
		,	ao.IronOfferCyclesID
		,	ao.ControlGroupID 
		,	ao.StartDate
		,	ao.EndDate
		,	ao.offerStartDate
		,	ao.offerEndDate
		,	ao.isWarehouse
		,	ao.IsVirgin
		,	cu.Exposed
		,	COALESCE(cu.CINID_Warehouse, cu.CINID_Virgin) AS CINID
	INTO #OfferReport_CTCustomers
	FROM #OfferReport_AllOffers ao
	INNER JOIN [Staging].[OfferReport_CTCustomers] cu
        ON cu.isWarehouse = ao.isWarehouse
		AND cu.IsVirgin = ao.IsVirgin
		AND cu.GroupID = ao.ControlGroupID
		AND Exposed = 0
	WHERE EXISTS (	SELECT 1
					FROM #OfferReport_ConsumerTransaction ct
					WHERE COALESCE(cu.CINID_Warehouse, cu.CINID_Virgin) = ct.CINID
					AND cu.isWarehouse = ao.isWarehouse
					AND cu.IsVirgin = ao.IsVirgin)

	INSERT INTO #OfferReport_CTCustomers
	SELECT	ao.PartnerID
		,	ao.IronOfferID
		,	ao.IronOfferCyclesID
		,	ao.ControlGroupID 
		,	ao.StartDate
		,	ao.EndDate
		,	ao.offerStartDate
		,	ao.offerEndDate
		,	ao.isWarehouse
		,	ao.IsVirgin
		,	cu.Exposed
		,	COALESCE(cu.CINID_Warehouse, cu.CINID_Virgin) AS CINID
	FROM #OfferReport_AllOffers ao
	INNER JOIN [Staging].[OfferReport_CTCustomers] cu
        ON cu.isWarehouse = ao.isWarehouse
		AND cu.IsVirgin = ao.IsVirgin
		AND cu.GroupID = ao.IronOfferCyclesID
		AND Exposed = 1
	WHERE EXISTS (	SELECT 1
					FROM #OfferReport_ConsumerTransaction ct
					WHERE COALESCE(cu.CINID_Warehouse, cu.CINID_Virgin) = ct.CINID
					AND cu.isWarehouse = ao.isWarehouse
					AND cu.IsVirgin = ao.IsVirgin)
		
	CREATE CLUSTERED INDEX CIX_CINID ON #OfferReport_CTCustomers (CINID)

	
    -- Get Metrics

    -- Above Total
    SELECT	cu.IronOfferID
		,	cu.Exposed
		,	cu.StartDate
		,	cu.EndDate
		,	cu.offerStartDate
		,	cu.offerEndDate
		,	cu.PartnerID
		,	cu.CINID
		,	cu.isWarehouse
		,	cu.IsVirgin
		,	cu.IronOfferCyclesID
		,	cu.ControlGroupID
		,	ct.Sales
		,	1 AS Spenders
		,	1 AS Threshold
		,	ct.ThresholdTrans
		,	ct.Channel
    FROM #OfferReport_CTCustomers cu
    CROSS APPLY (	SELECT	SUM(ct.Amount) Sales
						,	COUNT(1) ThresholdTrans
						,	NULL AS Channel
					FROM #OfferReport_ConsumerTransaction ct
					WHERE cu.CINID = ct.CINID
					AND cu.isWarehouse = ct.IsWarehouse
					AND cu.IsVirgin = ct.IsVirgin
					AND ct.AboveSpendStretch = 1) ct
    WHERE ct.Sales IS NOT NULL

    UNION ALL
 
    -- Below Total
    SELECT	cu.IronOfferID
		,	cu.Exposed
		,	cu.StartDate
		,	cu.EndDate
		,	cu.offerStartDate
		,	cu.offerEndDate
		,	cu.PartnerID
		,	cu.CINID
		,	cu.isWarehouse
		,	cu.IsVirgin
		,	cu.IronOfferCyclesID
		,	cu.ControlGroupID
		,	ct.Sales
		,	1 AS Spenders
		,	0 AS Threshold
		,	ct.ThresholdTrans
		,	ct.Channel
    FROM #OfferReport_CTCustomers cu
    CROSS APPLY (	SELECT	SUM(ct.Amount) Sales
						,	COUNT(1) ThresholdTrans
						,	NULL AS Channel
					FROM #OfferReport_ConsumerTransaction ct
					WHERE cu.CINID = ct.CINID
					AND cu.isWarehouse = ct.IsWarehouse
					AND cu.IsVirgin = ct.IsVirgin
					AND ct.AboveSpendStretch = 0) ct
    WHERE ct.Sales IS NOT NULL

    UNION ALL

    -- Above Channel
    SELECT	cu.IronOfferID
		,	cu.Exposed
		,	cu.StartDate
		,	cu.EndDate
		,	cu.offerStartDate
		,	cu.offerEndDate
		,	cu.PartnerID
		,	cu.CINID
		,	cu.isWarehouse
		,	cu.IsVirgin
		,	cu.IronOfferCyclesID
		,	cu.ControlGroupID
		,	ct.Sales
		,	1 AS Spenders
		,	1 AS Threshold
		,	ct.ThresholdTrans
		,	ct.Channel
    FROM #OfferReport_CTCustomers cu
    CROSS APPLY (	SELECT	SUM(ct.Amount) Sales
						,	COUNT(1) ThresholdTrans
						,	ct.IsOnline AS Channel
					FROM #OfferReport_ConsumerTransaction ct
					WHERE cu.CINID = ct.CINID
					AND cu.isWarehouse = ct.IsWarehouse
					AND cu.IsVirgin = ct.IsVirgin
					AND ct.AboveSpendStretch = 1
					GROUP BY ct.IsOnline) ct
    WHERE ct.Sales IS NOT NULL

    UNION ALL

    -- Below Channel
    SELECT	cu.IronOfferID
		,	cu.Exposed
		,	cu.StartDate
		,	cu.EndDate
		,	cu.offerStartDate
		,	cu.offerEndDate
		,	cu.PartnerID
		,	cu.CINID
		,	cu.isWarehouse
		,	cu.IsVirgin
		,	cu.IronOfferCyclesID
		,	cu.ControlGroupID
		,	ct.Sales
		,	1 AS Spenders
		,	0 AS Threshold
		,	ct.ThresholdTrans
		,	ct.Channel
    FROM #OfferReport_CTCustomers cu
    CROSS APPLY (	SELECT	SUM(ct.Amount) Sales
						,	COUNT(1) ThresholdTrans
						,	ct.IsOnline AS Channel
					FROM #OfferReport_ConsumerTransaction ct
					WHERE cu.CINID = ct.CINID
					AND cu.isWarehouse = ct.IsWarehouse
					AND cu.IsVirgin = ct.IsVirgin
					AND ct.AboveSpendStretch = 0
					GROUP BY ct.IsOnline) ct
    WHERE ct.Sales IS NOT NULL

END

