/******************************************************************************
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

31/07/2017 Hayden Reid
    - Changed query for performance considerations by creating cinid - offer table first
	   and then joining to CT using this new table


******************************************************************************/
CREATE PROCEDURE [Staging].[__OfferReport_Fetch_CTMetrics_Thresholdv2_Archived] (
    @ID INT
)
	
AS
BEGIN
		
	   SET NOCOUNT ON

    IF OBJECT_ID('Warehouse.Staging.OfferReport_BaseTable') IS NOT NULL TRUNCATE TABLE Warehouse.Staging.OfferReport_BaseTable -- CLean up spend stretch version
    IF OBJECT_ID('Warehouse.Staging.OfferReport_BaseOfferTable') IS NOT NULL DROP TABLE Warehouse.Staging.OfferReport_BaseOfferTable
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
		, o.ControlGroupTypeID
          , UpperValue
          , SpendStretch
          , o.offerStartDate
          , o.offerEndDate
    INTO Warehouse.Staging.OfferReport_BaseOfferTable
    FROM Staging.OfferReport_AllOffers o -- 2.0
    JOIN Staging.OfferReport_CTCustomers c 
          ON (
                (c.GroupID = o.ControlGroupID AND Exposed = 0)
                OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
          ) 
		AND (
		  c.isWarehouse = o.isWarehouse
		  OR (c.isWarehouse IS NULL AND o.isWarehouse IS NULL)
	   )
    inner JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
          ON oe.PartnerID = o.PartnerID
          AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    WHERE o.ID = @ID OR @ID IS NULL
	   
    IF OBJECT_ID('Warehouse.Staging.OfferReport_BaseThresholdTable') IS NOT NULL DROP TABLE Warehouse.Staging.OfferReport_BaseThresholdTable
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
		, c.Sales
		, c.Trans
		, c.Channel
		, c.Threshold
          -- these columns are added for joins/filters
          , o.PartnerID
		, o.ControlGroupTypeID
          , UpperValue
          , SpendStretch
          , o.offerStartDate
          , o.offerEndDate
    INTO Warehouse.Staging.OfferReport_BaseThresholdTable
    FROM Staging.OfferReport_AllOffers o -- 2.0
    JOIN Staging.OfferReport_ThresholdMetrics c 
	   ON c.IronOfferID = o.IronOfferID
	   AND (
		  c.IronOfferCyclesID = o.IronOfferCyclesID
		  OR (c.IronOfferCyclesID IS NULL AND o.IronOfferCyclesID IS NULL)
	   )
	   AND c.ControlGroupID = o.ControlGroupID
	   AND c.StartDate = o.StartDate
	   AND c.EndDate = o.EndDate
    inner JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
          ON oe.PartnerID = o.PartnerID
          AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    WHERE o.ID = @ID OR @ID IS NULL

   
    -- Main Results - Get Total Level
    SELECT
	   t.IronOfferID
	   , t.IronOfferCyclesID
	   , t.ControlGroupTypeID
	   , t.StartDate
	   , t.EndDate
	   , ct.Channel
	   , SUM(ct.Sales) Sales
	   , NULL Trans
	   , SUM(ct.ThresholdTrans) ThresholdTrans
	   , COUNT(DISTINCT t.CINID) as Spenders
	   , NULL Threshold
	   , t.Exposed
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.isWarehouse -- 2.0
    FROM Warehouse.Staging.OfferReport_BaseOfferTable t
    CROSS APPLY (
	   SELECT 
		  SUM(ct.Amount) Sales
		  , COUNT(1) ThresholdTrans
		  , NULL AS Channel
	   FROM Staging.OfferReport_ConsumerCombinations cc 
	   JOIN Relational.ConsumerTransaction ct with (nolock) 
		  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   WHERE cc.PartnerID = t.PartnerID
		  AND ct.CINID = t.CINID
		  AND ct.TranDate BETWEEN t.StartDate and t.EndDate
		  AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
		  AND ct.Amount > 0 and ct.Amount < t.UpperValue
    ) ct
    WHERE t.isWarehouse IS NOT NULL
	   AND ct.Sales IS NOT NULL
    GROUP BY 	   t.IronOfferID
	   , t.IronOfferCyclesID
	   , t.ControlGroupTypeID
	   , t.StartDate
	   , t.EndDate
	   , ct.Channel
	   	   , t.Exposed
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.isWarehouse

    UNION ALL

    -- Main Results - Channel Level
    SELECT
	   t.IronOfferID
	   , t.IronOfferCyclesID
	   , t.ControlGroupTypeID
	   , t.StartDate
	   , t.EndDate
	   , ct.Channel
	   , SUM(ct.Sales) Sales
	   , NULL Trans
	   , SUM(ct.ThresholdTrans) ThresholdTrans
	   , COUNT(DISTINCT t.CINID) as Spenders
	   , NULL Threshold
	   , t.Exposed
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.isWarehouse -- 2.0
    FROM Warehouse.Staging.OfferReport_BaseOfferTable t
    CROSS APPLY (
	   SELECT 
		  SUM(ct.Amount) Sales
		  , COUNT(1) ThresholdTrans
		  , ct.IsOnline AS Channel
	   FROM Staging.OfferReport_ConsumerCombinations cc 
	   JOIN Relational.ConsumerTransaction ct with (nolock) 
		  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   WHERE cc.PartnerID = t.PartnerID
		  AND ct.CINID = t.CINID
		  AND ct.TranDate BETWEEN t.StartDate and t.EndDate
		  AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
		  AND ct.Amount > 0 and ct.Amount < t.UpperValue
	   GROUP BY ct.IsOnline
    ) ct
    WHERE t.isWarehouse IS NOT NULL
	   AND ct.Sales IS NOT NULL
    GROUP BY 	   t.IronOfferID
	   , t.IronOfferCyclesID
	   , t.ControlGroupTypeID
	   , t.StartDate
	   , t.EndDate
	   , ct.Channel
	   	   , t.Exposed
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.isWarehouse

    UNION ALL

    -- Threshold Results - ALL
    SELECT
	   t.IronOfferID
	   , t.IronOfferCyclesID
	   , t.ControlGroupTypeID
	   , t.StartDate
	   , t.EndDate
	   , t.Channel
	   , SUM(t.Sales) Sales
	   , SUM(ct.Trans) Trans
	   , SUM(t.Trans) ThresholdTrans
	   , COUNT(DISTINCT t.CINID) as Spenders
	   , t.Threshold Threshold
	   , t.Exposed
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.isWarehouse -- 2.0
    FROM Warehouse.Staging.OfferReport_BaseThresholdTable t
    CROSS APPLY (
	   SELECT 
		  SUM(ct.Amount) Sales
		  , COUNT(1) Trans
	   FROM Staging.OfferReport_ConsumerCombinations cc 
	   JOIN Relational.ConsumerTransaction ct with (nolock) 
		  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   WHERE cc.PartnerID = t.PartnerID
		  AND ct.CINID = t.CINID
		  AND ct.TranDate BETWEEN t.StartDate and t.EndDate
		  AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
		  AND ct.Amount > 0 and ct.Amount < t.UpperValue
		  AND ( ct.isOnline = t.Channel OR t.Channel IS NULL)
    ) ct
    WHERE t.isWarehouse IS NOT NULL
	   AND ct.Sales IS NOT NULL
    GROUP BY 	   
	   t.IronOfferID
	   , t.IronOfferCyclesID
	   , t.ControlGroupTypeID
	   , t.StartDate
	   , t.EndDate
	   , t.Channel
	   , t.Exposed
	   , t.threshold
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.isWarehouse

    UNION ALL

    -- AMEX Results - Total Level 
    SELECT
	   t.IronOfferID
	   , t.IronOfferCyclesID
	   , t.ControlGroupTypeID
	   , t.StartDate
	   , t.EndDate
	   , ct.Channel
	   , SUM(ct.Sales) Sales
	   , NULL Trans
	   , SUM(ct.ThresholdTrans) ThresholdTrans
	   , COUNT(DISTINCT t.CINID) as Spenders
	   , NULL Threshold
	   , t.Exposed
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.isWarehouse -- 2.0
    FROM Warehouse.Staging.OfferReport_BaseOfferTable t
    CROSS APPLY (
	   SELECT 
		  SUM(ct.Amount) Sales
		  , COUNT(1) ThresholdTrans
		  , NULL AS Channel
	   FROM Staging.OfferReport_ConsumerCombinations cc 
	   JOIN Relational.ConsumerTransaction ct with (nolock) 
		  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   WHERE cc.PartnerID = t.PartnerID
		  AND ct.CINID = t.CINID
		  AND ct.TranDate BETWEEN t.StartDate and t.EndDate
		  AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
		  AND ct.Amount > ISNULL(t.SpendStretch, 0) and ct.Amount < t.UpperValue-- ONLY TRANSACTIONS ABOVE SPEND STRETCH
    ) ct
    WHERE t.isWarehouse IS NULL
	   AND ct.Sales IS NOT NULL
    GROUP BY 	   t.IronOfferID
	   , t.IronOfferCyclesID
	   , t.ControlGroupTypeID
	   , t.StartDate
	   , t.EndDate
	   , ct.Channel
	   	   , t.Exposed
	   , t.offerStartDate
	   , t.offerEndDate
	   , t.PartnerID
	   , t.isWarehouse

END




