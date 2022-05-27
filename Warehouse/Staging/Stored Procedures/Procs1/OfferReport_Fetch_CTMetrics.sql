/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the transactions for Warehouse Mailed, Control and nfi Control customers

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CTMetrics] 
	
AS
BEGIN
		
	SET NOCOUNT ON;

    -- Main Results - Get Total Level
    SELECT
	   o.IronOfferID
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
    FROM Staging.OfferReport_AllOffers o
    JOIN Staging.OfferReport_CTCustomersCINID c 
	   ON (c.GroupID = o.ControlGroupID AND Exposed = 0 AND c.PublisherID = o.PublisherID) 
	   OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1 AND c.PublisherID = o.PublisherID)
    JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = o.PartnerID
    JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    LEFT JOIN Staging.OfferReport_PublisherExclude pe -- Get publisher exclude dates based on when the cycle started to maintain consistency between partial and complete campaigns
	   ON pe.RetailerID = o.PartnerID
	   AND pe.PublisherID = o.PublisherID
	   AND o.offerStartDate between pe.StartDate and pe.EndDate
    JOIN Relational.ConsumerTransaction ct with (nolock) ON ct.CINID = c.CINID
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue
	   AND ((ct.TranDate < pe.StartDate or ct.TranDate > pe.EndDate) or pe.StartDate IS NULL) -- where the tran date is outside the publisher exclude dates (where applicable)
    WHERE o.PartnerID = 4265
    GROUP BY o.IronOfferID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID

    UNION ALL

    -- Main Results - Channel Level
    SELECT
	   o.IronOfferID
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
    FROM Staging.OfferReport_AllOffers o
    JOIN Staging.OfferReport_CTCustomersCINID c 
	   ON (c.GroupID = o.ControlGroupID AND Exposed = 0 AND c.PublisherID = o.PublisherID) 
	   OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1 AND c.PublisherID = o.PublisherID)
    JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = o.PartnerID
    JOIN Staging.OfferReport_OutlierExclusion oe 
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    LEFT JOIN Staging.OfferReport_PublisherExclude pe 
	   ON pe.RetailerID = o.PartnerID
	   AND pe.PublisherID = o.PublisherID
	   AND o.offerStartDate between pe.StartDate and pe.EndDate
    JOIN Relational.ConsumerTransaction ct with (nolock) ON ct.CINID = c.CINID
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue
	   AND ((ct.TranDate < pe.StartDate or ct.TranDate > pe.EndDate) or pe.StartDate IS NULL)
    WHERE o.PartnerID = 4265
    GROUP BY o.IronOfferID, ct.IsOnline, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID

    UNION ALL

    -- Threshold Results - Total Level - Above
    SELECT  
	   x.IronOfferID
	   , x.StartDate
	   , x.EndDate
	   , x.Channel
	   , COUNT(1) Trans
	   , x.Trans ThresholdTrans
	   , x.Sales
	   , COUNT(DISTINCT x.CINID) as Spenders
	   , 1 Threshold
	   , x.Exposed
	   , x.offerStartDate
	   , x.offerEndDate
	   , x.PartnerID
    FROM (
		  SELECT DISTINCT
			 ct.CINID
			 , SUM(ct.Amount) OVER (PARTITION BY c.Exposed, o.IronOfferID, o.offerStartDate, o.offerEndDate, o.StartDate, o.EndDate, o.PartnerID, o.PublisherID, o.SpendStretch, pe.StartDate, pe.EndDate, oe.UpperValue) Sales
			 , COUNT(1) OVER (PARTITION BY c.Exposed, o.IronOfferID, o.offerStartDate, o.offerEndDate, o.StartDate, o.EndDate, o.PartnerID, o.PublisherID, o.SpendStretch, pe.StartDate, pe.EndDate, oe.UpperValue) Trans
			 , NULL Channel
			 , c.Exposed
			 , o.IronOfferID
			 , o.offerStartDate
			 , o.offerEndDate
			 , o.StartDate
			 , o.EndDate
			 , o.PartnerID
			 , o.PublisherID
			 , o.SpendStretch
			 , pe.StartDate peStartDate
			 , pe.EndDate peEndDate
			 , oe.UpperValue
		  FROM Staging.OfferReport_AllOffers o
		  JOIN Staging.OfferReport_CTCustomersCINID c 
			 ON (c.GroupID = o.ControlGroupID AND Exposed = 0 AND c.PublisherID = o.PublisherID) 
			 OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1 AND c.PublisherID = o.PublisherID)
		  JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = o.PartnerID
		  JOIN Staging.OfferReport_OutlierExclusion oe 
			 ON oe.PartnerID = o.PartnerID
			 AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
		  LEFT JOIN Staging.OfferReport_PublisherExclude pe 
			 ON pe.RetailerID = o.PartnerID
			 AND pe.PublisherID = o.PublisherID
			 AND o.offerStartDate between pe.StartDate and pe.EndDate
		  JOIN Relational.ConsumerTransaction ct with (nolock) ON ct.CINID = c.CINID
			 AND ct.TranDate BETWEEN o.StartDate and o.EndDate
			 AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
			 AND ct.Amount > 0 and ct.Amount < oe.UpperValue AND ct.Amount >= o.SpendStretch
			 AND ((ct.TranDate < pe.StartDate or ct.TranDate > pe.EndDate) or pe.StartDate IS NULL)
		  WHERE o.PartnerID = 4265
	   ) x
    JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = x.PartnerID
    JOIN Relational.ConsumerTransaction ct with (nolock)
	   ON ct.CINID = x.CINID
	   AND ct.TranDate between x.StartDate and x.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < x.UpperValue
	   AND ((ct.TranDate < x.peStartDate or ct.TranDate > x.peEndDate) or x.peStartDate IS NULL) 
    GROUP BY x.IronOfferID, x.Exposed, x.StartDate, x.EndDate, x.offerStartDate, x.offerEndDate, x.PartnerID, x.Sales, x.Trans, x.Channel

    UNION ALL

    -- Threshold Results - Total Level - Below

    SELECT  
	   x.IronOfferID
	   , x.StartDate
	   , x.EndDate
	   , x.Channel
	   , COUNT(1) Trans
	   , x.Trans ThresholdTrans
	   , x.Sales
	   , COUNT(DISTINCT x.CINID) as Spenders
	   , 0 Threshold
	   , x.Exposed
	   , x.offerStartDate
	   , x.offerEndDate
	   , x.PartnerID
    FROM (
		  SELECT DISTINCT
			 ct.CINID
			 , SUM(ct.Amount) OVER (PARTITION BY c.Exposed, o.IronOfferID, o.offerStartDate, o.offerEndDate, o.StartDate, o.EndDate, o.PartnerID, o.PublisherID, o.SpendStretch, pe.StartDate, pe.EndDate, oe.UpperValue) Sales
			 , COUNT(1) OVER (PARTITION BY c.Exposed, o.IronOfferID, o.offerStartDate, o.offerEndDate, o.StartDate, o.EndDate, o.PartnerID, o.PublisherID, o.SpendStretch, pe.StartDate, pe.EndDate, oe.UpperValue) Trans
			 , NULL Channel
			 , c.Exposed
			 , o.IronOfferID
			 , o.offerStartDate
			 , o.offerEndDate
			 , o.StartDate
			 , o.EndDate
			 , o.PartnerID
			 , o.PublisherID
			 , o.SpendStretch
			 , pe.StartDate peStartDate
			 , pe.EndDate peEndDate
			 , oe.UpperValue
		  FROM Staging.OfferReport_AllOffers o
		  JOIN Staging.OfferReport_CTCustomersCINID c 
			 ON (c.GroupID = o.ControlGroupID AND Exposed = 0 AND c.PublisherID = o.PublisherID) 
			 OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1 AND c.PublisherID = o.PublisherID)
		  JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = o.PartnerID
		  JOIN Staging.OfferReport_OutlierExclusion oe 
			 ON oe.PartnerID = o.PartnerID
			 AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
		  LEFT JOIN Staging.OfferReport_PublisherExclude pe 
			 ON pe.RetailerID = o.PartnerID
			 AND pe.PublisherID = o.PublisherID
			 AND o.offerStartDate between pe.StartDate and pe.EndDate
		  JOIN Relational.ConsumerTransaction ct with (nolock) ON ct.CINID = c.CINID
			 AND ct.TranDate BETWEEN o.StartDate and o.EndDate
			 AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
			 AND ct.Amount > 0 and ct.Amount < oe.UpperValue AND ct.Amount < o.SpendStretch
			 AND ((ct.TranDate < pe.StartDate or ct.TranDate > pe.EndDate) or pe.StartDate IS NULL)
		  WHERE o.PartnerID = 4265
	   ) x
    JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = x.PartnerID
    JOIN Relational.ConsumerTransaction ct with (nolock)
	   ON ct.CINID = x.CINID
	   AND ct.TranDate between x.StartDate and x.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < x.UpperValue
	   AND ((ct.TranDate < x.peStartDate or ct.TranDate > x.peEndDate) or x.peStartDate IS NULL) 
    GROUP BY x.IronOfferID, x.Exposed, x.StartDate, x.EndDate, x.offerStartDate, x.offerEndDate, x.PartnerID, x.Sales, x.Trans, x.Channel

    UNION ALL
    -- Threshold Results - Channel Level - Above
    SELECT  
	   x.IronOfferID
	   , x.StartDate
	   , x.EndDate
	   , x.Channel
	   , COUNT(1) Trans
	   , x.Trans ThresholdTrans
	   , x.Sales
	   , COUNT(DISTINCT x.CINID) as Spenders
	   , 1 Threshold
	   , x.Exposed
	   , x.offerStartDate
	   , x.offerEndDate
	   , x.PartnerID
    FROM (
		  SELECT DISTINCT
			 ct.CINID
			 , SUM(ct.Amount) OVER (PARTITION BY c.Exposed, o.IronOfferID, o.offerStartDate, o.offerEndDate, o.StartDate, o.EndDate, o.PartnerID, o.PublisherID, o.SpendStretch, pe.StartDate, pe.EndDate, oe.UpperValue, ct.IsOnline) Sales
			 , COUNT(1) OVER (PARTITION BY c.Exposed, o.IronOfferID, o.offerStartDate, o.offerEndDate, o.StartDate, o.EndDate, o.PartnerID, o.PublisherID, o.SpendStretch, pe.StartDate, pe.EndDate, oe.UpperValue, ct.IsOnline) Trans
			 , ct.IsOnline Channel
			 , c.Exposed
			 , o.IronOfferID
			 , o.offerStartDate
			 , o.offerEndDate
			 , o.StartDate
			 , o.EndDate
			 , o.PartnerID
			 , o.PublisherID
			 , o.SpendStretch
			 , pe.StartDate peStartDate
			 , pe.EndDate peEndDate
			 , oe.UpperValue
		  FROM Staging.OfferReport_AllOffers o
		  JOIN Staging.OfferReport_CTCustomersCINID c 
			 ON (c.GroupID = o.ControlGroupID AND Exposed = 0 AND c.PublisherID = o.PublisherID) 
			 OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1 AND c.PublisherID = o.PublisherID)
		  JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = o.PartnerID
		  JOIN Staging.OfferReport_OutlierExclusion oe 
			 ON oe.PartnerID = o.PartnerID
			 AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
		  LEFT JOIN Staging.OfferReport_PublisherExclude pe 
			 ON pe.RetailerID = o.PartnerID
			 AND pe.PublisherID = o.PublisherID
			 AND o.offerStartDate between pe.StartDate and pe.EndDate
		  JOIN Relational.ConsumerTransaction ct with (nolock) ON ct.CINID = c.CINID
			 AND ct.TranDate BETWEEN o.StartDate and o.EndDate
			 AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
			 AND ct.Amount > 0 and ct.Amount < oe.UpperValue AND ct.Amount >= o.SpendStretch
			 AND ((ct.TranDate < pe.StartDate or ct.TranDate > pe.EndDate) or pe.StartDate IS NULL)
		  WHERE o.PartnerID = 4265
	   ) x
    JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = x.PartnerID
    JOIN Relational.ConsumerTransaction ct with (nolock)
	   ON ct.CINID = x.CINID
	   AND ct.TranDate between x.StartDate and x.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < x.UpperValue
	   AND ((ct.TranDate < x.peStartDate or ct.TranDate > x.peEndDate) or x.peStartDate IS NULL) 
	   AND ct.IsOnline = x.Channel
    GROUP BY x.IronOfferID, x.Exposed, x.StartDate, x.EndDate, x.offerStartDate, x.offerEndDate, x.PartnerID, x.Sales, x.Trans, x.Channel


    UNION ALL
    -- Threshold Results - Channel Level - Below
        SELECT  
	   x.IronOfferID
	   , x.StartDate
	   , x.EndDate
	   , x.Channel
	   , COUNT(1) Trans
	   , x.Trans ThresholdTrans
	   , x.Sales
	   , COUNT(DISTINCT x.CINID) as Spenders
	   , 0 Threshold
	   , x.Exposed
	   , x.offerStartDate
	   , x.offerEndDate
	   , x.PartnerID
    FROM (
		  SELECT DISTINCT
			 ct.CINID
			 , SUM(ct.Amount) OVER (PARTITION BY c.Exposed, o.IronOfferID, o.offerStartDate, o.offerEndDate, o.StartDate, o.EndDate, o.PartnerID, o.PublisherID, o.SpendStretch, pe.StartDate, pe.EndDate, oe.UpperValue, ct.IsOnline) Sales
			 , COUNT(1) OVER (PARTITION BY c.Exposed, o.IronOfferID, o.offerStartDate, o.offerEndDate, o.StartDate, o.EndDate, o.PartnerID, o.PublisherID, o.SpendStretch, pe.StartDate, pe.EndDate, oe.UpperValue, ct.IsOnline) Trans
			 , ct.IsOnline Channel
			 , c.Exposed
			 , o.IronOfferID
			 , o.offerStartDate
			 , o.offerEndDate
			 , o.StartDate
			 , o.EndDate
			 , o.PartnerID
			 , o.PublisherID
			 , o.SpendStretch
			 , pe.StartDate peStartDate
			 , pe.EndDate peEndDate
			 , oe.UpperValue
		  FROM Staging.OfferReport_AllOffers o
		  JOIN Staging.OfferReport_CTCustomersCINID c 
			 ON (c.GroupID = o.ControlGroupID AND Exposed = 0 AND c.PublisherID = o.PublisherID) 
			 OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1 AND c.PublisherID = o.PublisherID)
		  JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = o.PartnerID
		  JOIN Staging.OfferReport_OutlierExclusion oe 
			 ON oe.PartnerID = o.PartnerID
			 AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
		  LEFT JOIN Staging.OfferReport_PublisherExclude pe 
			 ON pe.RetailerID = o.PartnerID
			 AND pe.PublisherID = o.PublisherID
			 AND o.offerStartDate between pe.StartDate and pe.EndDate
		  JOIN Relational.ConsumerTransaction ct with (nolock) ON ct.CINID = c.CINID
			 AND ct.TranDate BETWEEN o.StartDate and o.EndDate
			 AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
			 AND ct.Amount > 0 and ct.Amount < oe.UpperValue AND ct.Amount < o.SpendStretch
			 AND ((ct.TranDate < pe.StartDate or ct.TranDate > pe.EndDate) or pe.StartDate IS NULL)
		  WHERE o.PartnerID = 4265
	   ) x
    JOIN Staging.OfferReport_ConsumerCombinations cc on cc.PartnerID = x.PartnerID
    JOIN Relational.ConsumerTransaction ct with (nolock)
	   ON ct.CINID = x.CINID
	   AND ct.TranDate between x.StartDate and x.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < x.UpperValue
	   AND ((ct.TranDate < x.peStartDate or ct.TranDate > x.peEndDate) or x.peStartDate IS NULL) 
	   AND ct.IsOnline = x.Channel
    GROUP BY x.IronOfferID, x.Exposed, x.StartDate, x.EndDate, x.offerStartDate, x.offerEndDate, x.PartnerID, x.Sales, x.Trans, x.Channel

END


