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

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ThresholdMetrics]
AS
	   
BEGIN
 
    SELECT
	   c.CINID
	   , o.IronOfferID
	   , o.IronOfferCyclesID
	   , o.ControlGroupID 
	   , o.StartDate
	   , o.EndDate
	   , NULL Channel
	   , SUM(ct.Amount) Sales
	   , COUNT(1) ThresholdTrans
	   , 1 as Spenders
	   , 1 Threshold
	   , c.Exposed
	   , c.isWarehouse -- 2.0
    FROM Staging.OfferReport_AllOffers o -- 2.0
    JOIN Staging.OfferReport_CTCustomers c 
	   ON (
		  (c.GroupID = o.ControlGroupID AND Exposed = 0)
		  OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
	   ) AND c.isWarehouse = o.isWarehouse
    JOIN Staging.OfferReport_ConsumerCombinations cc 
	   ON cc.PartnerID = o.PartnerID
    JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN Relational.ConsumerTransaction ct with (nolock) 
	   ON ct.CINID = c.CINID
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue and ct.Amount >= o.SpendStretch
    GROUP BY o.IronOfferID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.CINID, c.isWarehouse, o.IronOfferCyclesID, o.ControlGroupID

    UNION ALL

    SELECT
	   c.CINID
	   , o.IronOfferID
	   , o.IronOfferCyclesID
	   , o.ControlGroupID
	   , o.StartDate
	   , o.EndDate
	   , NULL Channel
	   , SUM(ct.Amount) Sales
	   , COUNT(1) ThresholdTrans
	   , 1 as Spenders
	   , 0 Threshold
	   , c.Exposed
	   , c.isWarehouse -- 2.0
    FROM Staging.OfferReport_AllOffers o -- 2.0
    JOIN Staging.OfferReport_CTCustomers c 
	   ON (
		  (c.GroupID = o.ControlGroupID AND Exposed = 0)
		  OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
	   ) AND c.isWarehouse = o.isWarehouse
    JOIN Staging.OfferReport_ConsumerCombinations cc 
	   ON cc.PartnerID = o.PartnerID
    JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN Relational.ConsumerTransaction ct with (nolock) 
	   ON ct.CINID = c.CINID
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue and ct.Amount < o.SpendStretch
    GROUP BY o.IronOfferID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.CINID, c.isWarehouse, o.IronOfferCyclesID, o.ControlGroupID

    UNION ALL
		  
    SELECT
	   c.CINID
	   , o.IronOfferID
	   , o.IronOfferCyclesID
	   , o.ControlGroupID
	   , o.StartDate
	   , o.EndDate
	   , ct.IsOnline Channel
	   , SUM(ct.Amount) Sales
	   , COUNT(1) ThresholdTrans
	   , 1 as Spenders
	   , 1 Threshold
	   , c.Exposed
	   , c.isWarehouse -- 2.0
    FROM Staging.OfferReport_AllOffers o
    JOIN Staging.OfferReport_CTCustomers c 
	   ON (
		  (c.GroupID = o.ControlGroupID AND Exposed = 0)
		  OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
	   ) AND c.isWarehouse = o.isWarehouse
    JOIN Staging.OfferReport_ConsumerCombinations cc 
	   ON cc.PartnerID = o.PartnerID
    JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN Relational.ConsumerTransaction ct with (nolock) 
	   ON ct.CINID = c.CINID
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue and ct.Amount >= o.SpendStretch
    GROUP BY o.IronOfferID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.CINID, ct.IsOnline, c.isWarehouse, o.IronOfferCyclesID, o.ControlGroupID    

    UNION ALL

    SELECT
	   c.CINID
	   , o.IronOfferID
	   , o.IronOfferCyclesID
	   , o.ControlGroupID
	   , o.StartDate
	   , o.EndDate
	   , ct.IsOnline Channel
	   , SUM(ct.Amount) Sales
	   , COUNT(1) ThresholdTrans
	   , 1 as Spenders
	   , 0 Threshold
	   , c.Exposed
	   , c.isWarehouse -- 2.0
    FROM Staging.OfferReport_AllOffers o -- 2.0
    JOIN Staging.OfferReport_CTCustomers c 
	   ON (
		  (c.GroupID = o.ControlGroupID AND Exposed = 0)
		  OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
	   ) AND c.isWarehouse = o.isWarehouse
    JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = o.PartnerID
    JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN Relational.ConsumerTransaction ct with (nolock) ON ct.CINID = c.CINID
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue and ct.Amount < o.SpendStretch
    GROUP BY o.IronOfferID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.CINID, ct.IsOnline, c.isWarehouse, o.IronOfferCyclesID, o.ControlGroupID

END