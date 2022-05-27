/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author	  Jason Shipp
Created	  13/04/2018
Purpose	
	- Gets the transactions for Warehouse Mailed, Control and nFI Control customers for Sainsburys
	- Uses intermediate table to avoid join to Relational.ConsumerTransaction, Staging.OfferReport_ConsumerCombinations or Staging.OfferReport_OutlierExclusion

Notes
	- No Transaction date condition needed if only one set of offer start and end dates exists in the cycle
	- Add AMEX fetch if AMEX offers ran in the cycle
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CTMetrics_Threshold_Sainsburys_Bespoke] (
    @ID INT
)
	
AS
BEGIN
		
	SET NOCOUNT ON;

	/******************************************************************************
	-- Populate intermediate table first

	Insert into Relational.ConsumerTransaction_Sainsburys
	Select ct.*
	From Warehouse.Relational.ConsumerTransaction ct with(nolock)
	Inner Join Staging.OfferReport_ConsumerCombinations cc with(nolock)
		ON cc.ConsumerCombinationID = ct.ConsumerCombinationID 
	where 
		ct.TranDate Between '2018-03-01' and '2018-03-28' -- Cycle dates
		and cc.PartnerID = 4708 -- Sainsburys
		and ct.Amount > 0
		-- and ct.Amount < 10000 -- UpperValue from Warehouse.Staging.OfferReport_OutlierExclusion; not using in latest calculation
	******************************************************************************/
	
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
	   , c.isWarehouse -- 2.0
    FROM Staging.OfferReport_AllOffers o -- 2.0
    JOIN Staging.OfferReport_CTCustomers c 
	   ON (
		  (c.GroupID = o.ControlGroupID AND Exposed = 0)
		  OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
	   ) AND c.isWarehouse = o.isWarehouse
   JOIN Relational.ConsumerTransaction_Sainsburys ct with (nolock) 
	   ON ct.CINID = c.CINID
	WHERE o.ID = @ID
    GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.isWarehouse

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
    FROM Staging.OfferReport_AllOffers o
    JOIN Staging.OfferReport_CTCustomers c 
	   ON (
		  (c.GroupID = o.ControlGroupID AND Exposed = 0)
		  OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
	   ) AND c.isWarehouse = o.isWarehouse
   JOIN Relational.ConsumerTransaction_Sainsburys ct with (nolock) ON ct.CINID = c.CINID	
    WHERE o.ID = @ID
    GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, ct.IsOnline, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.isWarehouse

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
	   , COUNT(1) Trans
	   , c.TotalTrans ThresholdTrans
	   , COUNT(DISTINCT c.CINID) as Spenders
	   , c.Threshold
	   , c.Exposed
	   , o.offerStartDate
	   , o.offerEndDate
	   , o.PartnerID
	   , c.isWarehouse -- 2.0
    FROM Staging.OfferReport_AllOffers o
    JOIN (
	   SELECT *
		  , SUM(Trans) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed, c.isWarehouse) TotalTrans
		  , SUM(Sales) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed, c.isWarehouse) TotalSales		   
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
    JOIN Relational.ConsumerTransaction_Sainsburys ct with (nolock) 
	   ON ct.CINID = c.CINID
	   AND (ct.IsOnline = c.Channel OR c.Channel IS NULL)
    WHERE o.ID = @ID
    GROUP BY o.IronOfferID, o.IronOfferCyclesID, o.ControlGroupTypeID, c.Channel, c.Exposed, o.StartDate, o.EndDate, o.offerStartDate, o.offerEndDate, o.PartnerID, c.Threshold, c.TotalTrans, c.TotalSales, c.isWarehouse;

	-- Add AMEX code if AMEX offers ran in period

END