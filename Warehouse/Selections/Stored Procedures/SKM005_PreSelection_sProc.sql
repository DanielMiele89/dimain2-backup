
CREATE PROCEDURE [Selections].[SKM005_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------------------------------------------------
-- BESPOKE OFFER SELECTION
-------------------------------------------------------------------------------------------------------------------------------


-- 1. All Sky Family My Reward DD Customers in the last 24 months (excl Sky Box Office)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
IF OBJECT_ID('tempdb..#all_skymobile_customersDD') IS NOT NULL DROP TABLE #all_skymobile_customersDD
SELECT  ctdd.FanID as 'CustomerFanID_DD'
	   ,cin.CINID as 'CustomerCINID_DD'
       --,ctdd.TranDate
	   --,ctdd.Amount
INTO #all_skymobile_customersDD
from warehouse.relational.ConsumerTransaction_DD_MyRewards ctdd
join warehouse.relational.ConsumerCombination_DD ccdd 
	on ctdd.ConsumerCombinationID_DD = ccdd.ConsumerCombinationID_DD
join warehouse.relational.customer cust
 on ctdd.fanid = cust.FanID 
join Warehouse.relational.cinlist cin
	on cust.SourceUID = cin.cin
and ccdd.brandid in (2674, 395, 1809, 2626, 2536)  -- 2674 Sky Mobile, 395 Sky, 1809 NOWTV.com TV, 2626 NOWTV.com Broadband; 2536	Sky Box Office)
and ctdd.TranDate >= dateadd(month, -24, getdate())
and ctdd.Amount >0

--Print output
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--select count(distinct CustomerCINID_DD) as 'SkyFamilyShoppersCIND_DD_1' from #all_skymobile_customersDD


-- 2. All Sky Family My Reward Customers in the last 24 months (excl Sky Box Office)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
IF OBJECT_ID('tempdb..#all_skymobile_customers_mr') IS NOT NULL DROP TABLE #all_skymobile_customers_mr
SELECT  ct.CINID as 'CustomerCIND'
	   --,ct.TranDate
	   --,ct.Amount
INTO #all_skymobile_customers_mr
from warehouse.relational.ConsumerTransaction_MyRewards ct
join warehouse.relational.ConsumerCombination cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
and cc.brandid in (2674, 395, 1809, 2626, 2536)  -- 2674 Sky Mobile, 395 Sky, 1809 NOWTV.com TV, 2626 NOWTV.com Broadband; 2536	Sky Box Office)
and ct.TranDate >= dateadd(month, -24, getdate())
and ct.Amount >0

--Print output
--select count(distinct CustomerCIND) as 'SkyFamilyShoppersMR_2' from #all_skymobile_customers_mr

-- 3. Merged Sky Customer List
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
IF OBJECT_ID('tempdb..#all_skymobile_customers_merged') IS NOT NULL DROP TABLE #all_skymobile_customers_merged
SELECT distinct CustomerCINID_DD
INTO #all_skymobile_customers_merged
from #all_skymobile_customersDD
union 
select distinct CustomerCIND from #all_skymobile_customers_mr

--Print output
--select count(*) as 'MergedList_3' from #all_skymobile_customers_merged

----Print output
--select * from #all_skymobile_customers_merged

-- 4 Full Customer Base
IF OBJECT_ID('tempdb..#FullBase') IS NOT NULL DROP TABLE #FullBase
select FanID, SourceUID
into #FullBase
from [Relational].[Customer]
where currentlyactive = 1

--Print output
select count(distinct SourceUID) as 'SourceUID_4' from #FullBase

--5 Full Base Lookup of CINIDs
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
IF OBJECT_ID('tempdb..#FullBaseCINID') IS NOT NULL DROP TABLE #FullBaseCINID
select distinct cinlist.CINID as 'CINID', fb.FanID
into #FullBaseCINID
from #FullBase fb
--join [Relational].[CINList] cinlist
left join [Relational].[CINList] cinlist
on cinlist.CIN = fb.SourceUID

--Print output
--select count(distinct CINID) as 'CINIDFB_5' from #FullBaseCINID


IF OBJECT_ID('tempdb..#all_skymobile_customers_merged_FanID') IS NOT NULL DROP TABLE #all_skymobile_customers_merged_FanID
SELECT	DISTINCT FanID
INTO #all_skymobile_customers_merged_FanID
FROM #all_skymobile_customers_merged clm
INNER JOIN Relational.CINList cl
	ON clm.CustomerCINID_DD = cl.CINID
INNER JOIN Relational.Customer cu
	ON cu.SourceUID = cl.CIN
	
IF OBJECT_ID('tempdb..#HouseholdIDs') IS NOT NULL DROP TABLE #HouseholdIDs
SELECT	DISTINCT HouseholdID
INTO #HouseholdIDs
FROM Relational.MFDD_Households hh
WHERE EXISTS (	SELECT 1
				FROM #all_skymobile_customers_merged_FanID ac
				WHERE hh.FanID = ac.fanID)
AND EndDate IS NULL

IF OBJECT_ID('tempdb..#FanIDs') IS NOT NULL DROP TABLE #FanIDs
SELECT	DISTINCT FanID
INTO #FanIDs
FROM Relational.MFDD_Households hh
WHERE EXISTS (	SELECT 1
				FROM #HouseholdIDs ac
				WHERE hh.HouseholdID = ac.HouseholdID)
AND EndDate IS NULL

----6 Target Customer CINIDs
IF OBJECT_ID('tempdb..#TargetCust') IS NOT NULL DROP TABLE #TargetCust
select	CINID
	,	FanID
into #TargetCust
from #FullBaseCINID fbcinid
--where fbcinid.CINID <> merged.CustomerCINID_DD
where FanID not in (select distinct FanID from #FanIDs)

--Print output
--select count(distinct CINID) as 'TargetCust' from #TargetCust

	IF OBJECT_ID('[Warehouse].[Selections].[SKM005_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[SKM005_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[SKM005_PreSelection]
	FROM #TargetCust
	

END