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
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ThresholdMetricsv2] (
    @ID INT = NULL
)
AS
	   
BEGIN
	
    IF OBJECT_ID('Warehouse.Staging.OfferReport_BaseTable') IS NOT NULL DROP TABLE Warehouse.Staging.OfferReport_BaseTable
    -- Set up base table
    SELECT
          c.CINID
          , o.IronOfferID
          , o.IronOfferCyclesID
          , o.ControlGroupID 
          , o.StartDate
          , o.EndDate
          , c.Exposed
          , c.isWarehouse -- 2.0
          -- these columns are added for joins/filters
          , o.PartnerID
          , UpperValue
          , SpendStretch
          , o.offerStartDate
          , o.offerEndDate
    INTO Warehouse.Staging.OfferReport_BaseTable
    FROM Staging.OfferReport_AllOffers o -- 2.0
	INNER JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
          ON oe.PartnerID = o.PartnerID
          AND o.OfferStartDate BETWEEN oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    INNER JOIN Staging.OfferReport_CTCustomers c -- Chris suggests INNER LOOP JOIN
          ON (
                (c.GroupID = o.ControlGroupID AND Exposed = 0)
                OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
          ) AND c.isWarehouse = o.isWarehouse
     WHERE (o.ID = @ID OR @ID IS NULL) AND o.SpendStretch IS NOT NULL

    CREATE CLUSTERED INDEX CIX_OR_BaseTable_Customer ON Warehouse.Staging.OfferReport_BaseTable (CINID, StartDate, EndDate, PartnerID, UpperValue, SpendStretch)

    -- Get Metrics

    -- Above Total
    SELECT 
	   t.IronOfferID
	   , t.Exposed
	   , t.StartDate
	   , t.EndDate
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.CINID
	   , t.isWarehouse
	   , t.IronOfferCyclesID
	   , t.ControlGroupID
	   , x.Sales
	   , 1 AS Spenders
	   , 1 AS Threshold
        , x.ThresholdTrans
	   , x.Channel
    --into #t2
    FROM Warehouse.Staging.OfferReport_BaseTable t
    CROSS APPLY (
		 SELECT SUM(ct.Amount) Sales
		    , COUNT(1) ThresholdTrans
		    , NULL AS Channel
		 FROM Staging.OfferReport_ConsumerCombinations cc 
		 INNER JOIN Relational.ConsumerTransaction ct 
			   ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		 WHERE cc.PartnerID = t.PartnerID
			   AND ct.CINID = t.CINID
			   AND ct.TranDate BETWEEN t.StartDate and t.EndDate
			   AND ct.Amount > 0 
			   and ct.Amount < t.UpperValue 
			   and ct.Amount >= t.SpendStretch
    ) x
    WHERE x.Sales IS NOT NULL

    UNION ALL
 
    -- Below Total
    SELECT 
	   t.IronOfferID
	   , t.Exposed
	   , t.StartDate
	   , t.EndDate
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.CINID
	   , t.isWarehouse
	   , t.IronOfferCyclesID
	   , t.ControlGroupID
	   , x.Sales
	   , 1 AS Spenders
	   , 0 AS Threshold
        , x.ThresholdTrans
	   , x.Channel
    FROM Warehouse.Staging.OfferReport_BaseTable t
    CROSS APPLY (
		 SELECT SUM(ct.Amount) Sales
		    , COUNT(1) ThresholdTrans
		    , NULL AS Channel
		 FROM Staging.OfferReport_ConsumerCombinations cc 
		 INNER JOIN Relational.ConsumerTransaction ct 
			   ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		 WHERE cc.PartnerID = t.PartnerID
			   AND ct.CINID = t.CINID
			   AND ct.TranDate BETWEEN t.StartDate and t.EndDate
			   AND ct.Amount > 0 
			   and ct.Amount < t.UpperValue 
			   and ct.Amount < t.SpendStretch
    ) x
    WHERE x.Sales IS NOT NULL

    UNION ALL

    -- Above Channel
    SELECT 
	   t.IronOfferID
	   , t.Exposed
	   , t.StartDate
	   , t.EndDate
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.CINID
	   , t.isWarehouse
	   , t.IronOfferCyclesID
	   , t.ControlGroupID
	   , x.Sales
	   , 1 AS Spenders
	   , 1 AS Threshold
        , x.ThresholdTrans
	   , x.Channel
    FROM Warehouse.Staging.OfferReport_BaseTable t
    CROSS APPLY (
		 SELECT SUM(ct.Amount) Sales
		    , COUNT(1) ThresholdTrans
		    , ct.IsOnline AS Channel
		 FROM Staging.OfferReport_ConsumerCombinations cc 
		 INNER JOIN Relational.ConsumerTransaction ct 
			   ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		 WHERE cc.PartnerID = t.PartnerID
			   AND ct.CINID = t.CINID
			   AND ct.TranDate BETWEEN t.StartDate and t.EndDate
			   AND ct.Amount > 0 
			   and ct.Amount < t.UpperValue 
			   and ct.Amount >= t.SpendStretch
		  GROUP BY ct.IsOnline
    ) x
    WHERE x.Sales IS NOT NULL

    UNION ALL

    -- Below Channel
    SELECT 
	   t.IronOfferID
	   , t.Exposed
	   , t.StartDate
	   , t.EndDate
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.CINID
	   , t.isWarehouse
	   , t.IronOfferCyclesID
	   , t.ControlGroupID
	   , x.Sales
	   , 1 AS Spenders
	   , 0 AS Threshold
        , x.ThresholdTrans
	   , x.Channel
    FROM Warehouse.Staging.OfferReport_BaseTable t
    CROSS APPLY (
		 SELECT SUM(ct.Amount) Sales
		    , COUNT(1) ThresholdTrans
		    , ct.IsOnline AS Channel
		 FROM Staging.OfferReport_ConsumerCombinations cc 
		 INNER JOIN Relational.ConsumerTransaction ct 
			   ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		 WHERE cc.PartnerID = t.PartnerID
			   AND ct.CINID = t.CINID
			   AND ct.TranDate BETWEEN t.StartDate and t.EndDate
			   AND ct.Amount > 0 
			   and ct.Amount < t.UpperValue 
			   and ct.Amount < t.SpendStretch
		  GROUP BY ct.IsOnline
    ) x
    WHERE x.Sales IS NOT NULL

END 

