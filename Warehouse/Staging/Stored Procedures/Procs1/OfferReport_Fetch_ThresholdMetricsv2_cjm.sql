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

13/01/2020 ChrisM
	- modified for perf

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ThresholdMetricsv2_cjm] (
    @ID INT = NULL
)
AS
	   
BEGIN

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
IF OBJECT_ID('Warehouse.Staging.OfferReport_BaseTable') IS NOT NULL DROP TABLE Warehouse.Staging.OfferReport_BaseTable
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
INNER JOIN Staging.OfferReport_CTCustomers c 
	ON c.GroupID = o.ControlGroupID                 
	AND c.isWarehouse = o.isWarehouse
inner JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	ON oe.PartnerID = o.PartnerID
	AND o.OfferStartDate BETWEEN oe.StartDate and ISNULL(oe.EndDate, GETDATE())
WHERE 1 = 1
	AND (o.ID = @ID OR @ID IS NULL) 
	AND o.SpendStretch IS NOT NULL
	AND c.Exposed = 0

INSERT INTO Warehouse.Staging.OfferReport_BaseTable (
	CINID, IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Exposed, 
	isWarehouse, PartnerID, UpperValue, SpendStretch, offerStartDate, offerEndDate
)
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
FROM Staging.OfferReport_AllOffers o -- 2.0
INNER JOIN Staging.OfferReport_CTCustomers c 
	ON c.GroupID = o.IronOfferCyclesID                 
	AND c.isWarehouse = o.isWarehouse
INNER JOIN Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
	ON oe.PartnerID = o.PartnerID
	AND o.OfferStartDate BETWEEN oe.StartDate and ISNULL(oe.EndDate, GETDATE())
WHERE 1 = 1
	AND (o.ID = @ID OR @ID IS NULL) 
	AND o.SpendStretch IS NOT NULL
	AND c.Exposed = 1
-- 6,805,799 / 00:00:26

CREATE CLUSTERED INDEX cx_01 ON Warehouse.Staging.OfferReport_BaseTable (StartDate, PartnerID)
--CREATE INDEX ix_Stuff1 ON Warehouse.Staging.OfferReport_BaseTable (CINID, StartDate, EndDate, PartnerID, UpperValue, SpendStretch)


----------------------------------------------------------------------------------
-- Get Metrics
----------------------------------------------------------------------------------

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
	--, 1 AS Threshold
	, Threshold = x.[Filter]
    , x.ThresholdTrans
	, x.Channel
FROM Warehouse.Staging.OfferReport_BaseTable t
CROSS APPLY (
	SELECT 
		y.[Filter]
		, SUM(ct.Amount) Sales
		, COUNT(1) ThresholdTrans
		, NULL AS Channel
	FROM Staging.OfferReport_ConsumerCombinations cc 
	INNER JOIN Relational.ConsumerTransaction ct 
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	CROSS APPLY (SELECT [Filter] = CASE WHEN ct.Amount >= t.SpendStretch THEN 0 ELSE 1 END) y
	WHERE cc.PartnerID = t.PartnerID
		AND ct.CINID = t.CINID
		AND ct.TranDate BETWEEN t.StartDate and t.EndDate
		AND ct.Amount > 0 
		and ct.Amount < t.UpperValue 
		--and ct.Amount >= t.SpendStretch
	GROUP BY y.[Filter]
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
	--, 1 AS Threshold
	, Threshold = x.[Filter]
    , x.ThresholdTrans
	, x.Channel
FROM Warehouse.Staging.OfferReport_BaseTable t
CROSS APPLY (
	SELECT 
		y.[Filter]
		, SUM(ct.Amount) Sales
		, COUNT(1) ThresholdTrans
		, ct.IsOnline AS Channel
	FROM Staging.OfferReport_ConsumerCombinations cc 
	INNER JOIN Relational.ConsumerTransaction ct 
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	CROSS APPLY (SELECT [Filter] = CASE WHEN ct.Amount >= t.SpendStretch THEN 0 ELSE 1 END) y
	WHERE cc.PartnerID = t.PartnerID
		AND ct.CINID = t.CINID
		AND ct.TranDate BETWEEN t.StartDate and t.EndDate
		AND ct.Amount > 0 
		and ct.Amount < t.UpperValue 
		--and ct.Amount >= t.SpendStretch
	GROUP BY ct.IsOnline, y.[Filter]
) x
WHERE x.Sales IS NOT NULL

END 


RETURN 0

