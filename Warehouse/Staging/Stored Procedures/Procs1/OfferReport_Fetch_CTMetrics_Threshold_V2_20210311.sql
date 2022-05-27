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

22/10/2018 Jason Shipp 
	- Changed logic to count distinct transactions when calculating AllTransThreshold, and removed unnecessary join to [Staging].[OfferReport_ConsumerTransaction]

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CTMetrics_Threshold_V2_20210311] (@ID INT)
	
AS
BEGIN
		
	   SET NOCOUNT ON
	
	--	DECLARE @ID INT = 1

    -- Main Results - Get Total Level
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
	   , c.IsWarehouse -- 2.0
	   , c.IsVirgin -- 2.0
    FROM Staging.OfferReport_AllOffers o -- 2.0
    JOIN Staging.OfferReport_CTCustomers c 
		ON ((	c.GroupID = o.ControlGroupID AND Exposed = 0)
			OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1))
		AND c.IsWarehouse = o.IsWarehouse
		AND c.IsVirgin = o.IsVirgin
    JOIN Staging.OfferReport_ConsumerCombinations cc 
	   ON cc.PartnerID = o.PartnerID
		AND cc.IsWarehouse = o.IsWarehouse
		AND cc.IsVirgin = o.IsVirgin
    JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN [Staging].[OfferReport_ConsumerTransaction] ct with (nolock) 
	   ON ct.CINID = COALESCE(c.CINID_Warehouse, c.CINID_Virgin)
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue
		AND ct.IsWarehouse = o.IsWarehouse
		AND ct.IsVirgin = o.IsVirgin
    WHERE o.ID = @ID
    GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.IsWarehouse, c.IsVirgin


    UNION ALL

    -- Main Results - Channel Level
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
    FROM Staging.OfferReport_AllOffers o
    JOIN Staging.OfferReport_CTCustomers c 
		ON ((	c.GroupID = o.ControlGroupID AND Exposed = 0)
			OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1))
		AND c.IsWarehouse = o.IsWarehouse
		AND c.IsVirgin = o.IsVirgin
    JOIN Staging.OfferReport_ConsumerCombinations cc
		on cc.PartnerID = o.PartnerID
		AND cc.IsWarehouse = o.IsWarehouse
		AND cc.IsVirgin = o.IsVirgin
    JOIN Staging.OfferReport_OutlierExclusion oe 
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN [Staging].[OfferReport_ConsumerTransaction] ct with (nolock)
	   ON ct.CINID = COALESCE(c.CINID_Warehouse, c.CINID_Virgin)
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue
		AND ct.IsWarehouse = o.IsWarehouse
		AND ct.IsVirgin = o.IsVirgin
    WHERE o.ID = @ID
    GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, ct.IsOnline, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.isWarehouse, c.IsVirgin

    UNION ALL
    
	--Threshold Results
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
    FROM Staging.OfferReport_AllOffers o
    JOIN Staging.OfferReport_ConsumerCombinations cc 
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
	   FROM Staging.OfferReport_ThresholdMetrics c
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
    WHERE o.ID = @ID
    GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, c.Channel, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.Threshold, c.TotalTrans, TotalTrans2, c.TotalSales, c.isWarehouse, c.IsVirgin
    
    UNION ALL

    /** AMEX Offers **/
	   --AMEX Results - Get Total Level
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
    FROM Staging.OfferReport_AllOffers o -- 2.0
    JOIN Staging.OfferReport_CTCustomers c 
	   ON (
		  (c.GroupID = o.ControlGroupID AND Exposed = 0)
		  OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
	   ) 
	   AND c.isWarehouse IS NULL
	   AND c.IsVirgin IS NULL
	   AND o.isWarehouse IS NULL -- 2.0
	   AND o.IsVirgin IS NULL -- 2.0
    JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = o.PartnerID
    JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN [Staging].[OfferReport_ConsumerTransaction] ct with (nolock)
		ON ct.CINID = COALESCE(c.CINID_Warehouse, c.CINID_Virgin)
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > ISNULL(o.SpendStretch, 0) and ct.Amount < oe.UpperValue -- ONLY TRANSACTIONS ABOVE SPEND STRETCH
    WHERE o.ID = @ID
    GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.isWarehouse, c.IsVirgin
	OPTION(RECOMPILE) -- Added by Jason Shipp 06/04/2018

END