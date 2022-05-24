/******************************************************************************  PROCESS NAME: Offer Calculation - Calculate Performance 
- Fetch CT Metrics    Author   Hayden Reid  Created   23/09/2016  Purpose   Gets the transactions for Warehouse Mailed, Control and nfi Control customers    Copyright © 2016, Reward, All Rights Reserved  
------------------------------------------------------------------------------  Modification History    03/01/2017  Hayden Reid      
- Added UNION for AMEX offers.  When AMEX becomes an official publisher, this union will need to be changed to account for it.    02/05/2017 Hayden Reid - 2.0 Upgrade      
- Changed logic from PublisherID to [isWarehouse]      - Removed PublisherExclude      
- Prevented the possibility of creating a distinct customer group however,      on further inspection, if an offer is excluded at the point of input, this table is      not required for further filtering    
******************************************************************************/  
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CTMetrics_Threshold_CJM] (      @ID INT  )     
AS  
BEGIN          
SET NOCOUNT ON         

IF OBJECT_ID('tempdb..#OfferReport_OutlierExclusion') IS NOT NULL DROP TABLE #OfferReport_OutlierExclusion;
SELECT  --o.ID,    
	o.isWarehouse,
	o.ControlGroupID,
	o.IronOfferID, 
	o.IronOfferCyclesID, 
	o.ControlGroupTypeID, 
	o.StartDate, 
	o.EndDate, 
	o.offerStartDate, 
	o.offerEndDate, 
	o.PartnerID,
	oe.UpperValue,
	cc.ConsumerCombinationID,
	o.SpendStretch	        
INTO #OfferReport_OutlierExclusion
FROM Staging.OfferReport_AllOffers o -- 2.0      
JOIN Staging.OfferReport_OutlierExclusion oe       
	ON oe.PartnerID = o.PartnerID      
	AND o.OfferStartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, GETDATE())      
JOIN Staging.OfferReport_ConsumerCombinations cc 
	ON cc.PartnerID = o.PartnerID -- (1573132 rows affected) / 00:00:06
WHERE o.ID = @ID  

CREATE CLUSTERED INDEX cx_Stuff ON #OfferReport_OutlierExclusion (isWarehouse, ControlGroupID, IronOfferCyclesID, ConsumerCombinationID)



-- Main Results - Get Total Level      
SELECT      o.IronOfferID      , o.IronOfferCyclesID      , o.ControlGroupTypeID      , o.StartDate      , o.EndDate      , NULL Channel      
	, SUM(ct.Amount) Sales      , NULL Trans      , COUNT(1) ThresholdTrans      , COUNT(DISTINCT ct.CINID) as Spenders      
	, NULL Threshold      , c.Exposed      , o.offerStartDate      , o.offerEndDate      , o.PartnerID      , c.isWarehouse -- 2.0      
FROM #OfferReport_OutlierExclusion o      
JOIN Staging.OfferReport_CTCustomers c       
	ON (      (c.GroupID = o.ControlGroupID AND Exposed = 0)      
	OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)      ) AND c.isWarehouse = o.isWarehouse      
JOIN Relational.ConsumerTransaction ct with (nolock)       
	ON ct.CINID = c.CINID      
	AND ct.TranDate BETWEEN o.StartDate and o.EndDate      
	AND ct.ConsumerCombinationID = o.ConsumerCombinationID      
	AND ct.Amount > 0 and ct.Amount < o.UpperValue      
--WHERE o.ID = @ID      
GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, 
	c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.isWarehouse        

UNION ALL        

-- Main Results - Channel Level      
SELECT      o.IronOfferID      , o.IronOfferCyclesID      , o.ControlGroupTypeID      , o.StartDate      , o.EndDate      , ct.IsOnline Channel      
	, SUM(ct.Amount) Sales      , NULL Trans, COUNT(1) ThresholdTrans      , COUNT(DISTINCT ct.CINID) as Spenders      
	, NULL Threshold      , c.Exposed      , o.offerStartDate      , o.offerEndDate      , o.PartnerID      , c.isWarehouse      
FROM #OfferReport_OutlierExclusion o   
JOIN Staging.OfferReport_CTCustomers c       
	ON (      (c.GroupID = o.ControlGroupID AND Exposed = 0)      
	OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)      ) 
	AND c.isWarehouse = o.isWarehouse      
JOIN Relational.ConsumerTransaction ct with (nolock) ON ct.CINID = c.CINID      
	AND ct.TranDate BETWEEN o.StartDate and o.EndDate      
	AND ct.ConsumerCombinationID = o.ConsumerCombinationID      
	AND ct.Amount > 0 and ct.Amount < o.UpperValue      
--WHERE o.ID = @ID      
GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, 
	ct.IsOnline, 
	c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.isWarehouse        

UNION ALL

--Threshold Results      
SELECT      o.IronOfferID      , o.IronOfferCyclesID      , o.ControlGroupTypeID      , o.StartDate      
			  , o.EndDate      , c.Channel Channel      , c.TotalSales Sales      , COUNT(1) Trans      
	, c.TotalTrans ThresholdTrans      , COUNT(DISTINCT c.CINID) as Spenders      , c.Threshold      , c.Exposed      
	, o.offerStartDate      , o.offerEndDate      , o.PartnerID      , c.isWarehouse -- 2.0      
FROM #OfferReport_OutlierExclusion o
JOIN (      
	SELECT *      
		, SUM(Trans) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed, c.isWarehouse) TotalTrans      
		, SUM(Sales) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed, c.isWarehouse) TotalSales           
	FROM Staging.OfferReport_ThresholdMetrics c      
) c      
	ON c.IronOfferID = o.IronOfferID      
	AND (      c.IronOfferCyclesID = o.IronOfferCyclesID      OR (c.IronOfferCyclesID IS NULL AND o.IronOfferCyclesID IS NULL)      )      
	AND c.ControlGroupID = o.ControlGroupID      AND c.StartDate = o.StartDate      AND c.EndDate = o.EndDate      
JOIN Relational.ConsumerTransaction ct with (nolock)       
	ON ct.CINID = c.CINID      
	AND ct.TranDate BETWEEN c.StartDate and c.EndDate      
	AND ct.ConsumerCombinationID = o.ConsumerCombinationID      
	AND ct.Amount > 0 and ct.Amount < o.UpperValue      AND (ct.IsOnline = c.Channel OR c.Channel IS NULL)      
--WHERE o.ID = @ID      
GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, 
	c.Channel, 
	c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.Threshold, c.TotalTrans, c.TotalSales, c.isWarehouse            

UNION ALL

/** AMEX Offers **/      --AMEX Results - Get Total Level      
SELECT      o.IronOfferID      , o.IronOfferCyclesID      , o.ControlGroupTypeID      , o.StartDate      , o.EndDate      , NULL Channel      , SUM(ct.Amount) Sales      
	, NULL Trans      , COUNT(1) ThresholdTrans      , COUNT(DISTINCT ct.CINID) as Spenders      , NULL Threshold      
	, c.Exposed      , o.offerStartDate      , o.offerEndDate      , o.PartnerID      , c.isWarehouse -- 2.0      
FROM #OfferReport_OutlierExclusion o      
JOIN Staging.OfferReport_CTCustomers c       
	ON (      (c.GroupID = o.ControlGroupID AND Exposed = 0)      OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)      )       
	AND c.isWarehouse IS NULL AND o.isWarehouse IS NULL -- 2.0      
JOIN Relational.ConsumerTransaction ct with (nolock) 
	ON ct.CINID = c.CINID      
	AND ct.TranDate BETWEEN o.StartDate and o.EndDate      
	AND ct.ConsumerCombinationID = o.ConsumerCombinationID      
	AND ct.Amount > ISNULL(o.SpendStretch, 0) 
	and ct.Amount < o.UpperValue -- ONLY TRANSACTIONS ABOVE SPEND STRETCH      
--WHERE o.ID = @ID      
GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, 
	c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.isWarehouse   

--OPTION(RECOMPILE) -- Added by Jason Shipp 06/04/2018    
END  



