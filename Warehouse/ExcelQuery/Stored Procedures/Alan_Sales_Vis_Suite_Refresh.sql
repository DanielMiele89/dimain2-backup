

/*=================================================================================================
Sales Visualisation Refresh
Version 1: A. Devereux 25/02/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 1 Hour

CREATE PROCEDURE [ExcelQuery].[Alan_Sales_Vis_Suite_Refresh]	(@Sdate Date	--start date
															,@Edate Date)	--end date
AS
BEGIN
	SET NOCOUNT ON;
-----------  Sales Visualisation Data Extraction -----------------

----------------------------------------------------------------------------------------
----------  Get Brand List
----------------------------------------------------------------------------------------

if object_id('tempdb..#brandlist1') is not null drop table #brandlist1

select b.BrandID
into #brandlist1
from warehouse.MI.SalesFunnel s
join warehouse.Relational.Brand b on s.BrandID=b.BrandID
group by b.BrandID
having max(FunnelStatus) not in (0)

if object_id('tempdb..#brandlist2') is not null drop table #brandlist2

select top 500 b.BrandID
into #brandlist2
from Warehouse.mi.TotalBrandSpend s
left join warehouse.Relational.Brand b on s.BrandID=b.BrandID
order by SpendThisYear desc

if object_id('tempdb..#brandlist3') is not null drop table #brandlist3

select top 500 b.BrandID
into #brandlist3
from Warehouse.mi.TotalBrandSpend_CBP s
left join warehouse.Relational.Brand b on s.BrandID=b.BrandID
order by SpendThisYear desc

if object_id('tempdb..#brandlist4') is not null drop table #brandlist4

select BrandID 
into #brandlist4
from warehouse.Relational.Partner


if object_id('tempdb..#brandlistfull') is not null drop table #brandlistfull

SELECT *
  INTO  #brandlistfull
FROM
(
        SELECT     *
    FROM         #brandlist1
    UNION
    SELECT     *
    FROM         #brandlist2
    UNION
    SELECT     *
    FROM         #brandlist3
    UNION
    SELECT     *
    FROM         #brandlist4
) bf


CREATE clustered INDEX Brand0 ON #brandlistfull(BrandID)
--select * from #BrandID
-- Regroup the Brand and create lookup here...

----------------------------------------------------------------------------------------
----------  Get Consumer Combinations
----------------------------------------------------------------------------------------

if object_id('tempdb..#lk_brand') is not null drop table #lk_brand

select b.brandid
       ,brandname
	   ,ConsumerCombinationID
	   ,BrandGroupID  
into #lk_brand
from #brandlistfull b
inner join relational.ConsumerCombination bm on b.brandid=bm.BrandID
inner join		warehouse.Relational.Brand tb on tb.BrandID = b.BrandID

-- index... 
CREATE clustered INDEX ix_CC ON #lk_brand (ConsumerCombinationID)
----------------------------------------------------------------------------------------
----------  Get Customer Base
----------------------------------------------------------------------------------------

if object_id('warehouse.insightarchive.SalesVisSuite_FixedBase') is not null drop table warehouse.insightarchive.SalesVisSuite_FixedBase
EXEC warehouse.Relational.CustomerBase_Generate 'SalesVisSuite_FixedBase', @Sdate, @Edate 

---------------------------------------------------------------------------------------
----------  Get Transaction data
---------------------------------------------------------------------------------------

if object_id('tempdb..#Transact_All2') is not null drop table #Transact_All2

select sum(Amount) as sales
       ,count(*) as trans
	   ,BrandName
	   ,TranDate
	   ,IsOnline

into #Transact_All2
from Warehouse.Relational.ConsumerTransaction tr with (nolock)
inner join warehouse.insightarchive.SalesVisSuite_FixedBase c on tr.CINID=c.CINID
inner join #lk_brand lk_b on tr.ConsumerCombinationID=lk_b.ConsumerCombinationID  -- in the brands
where tr.TranDate between @Sdate and @Edate
GROUP BY	isonline 
	   ,BrandName
	   ,TranDate
	   ,IsOnline

--select top 100 * from #Transact_All2


----------------------------------------------------------------------------------------
----------  Aggregate Transactional Information
----------------------------------------------------------------------------------------
if object_id('warehouse.excelQuery.SalesVisSuite_Data') is not null drop table warehouse.excelquery.SalesVisSuite_Data


select 	   TranDate
		,BrandName
	   ,sum(sales) as All_sales
       ,sum(trans) as All_trans
	   ,sum(case when isonline=1 then sales else 0 end) as Online_sales
	   ,sum(case when isonline=1 then trans else 0 end) as Online_trans
	   ,sum(case when isonline=0 then sales else 0 end) as Store_Sales
	   ,sum(case when isonline=0 then trans else 0 end) as Store_trans


into warehouse.excelquery.SalesVisSuite_Data
from #Transact_All2
where TranDate between @Sdate and @Edate
GROUP BY TranDate
		,BrandName

if object_id('warehouse.insightarchive.SalesVisSuite_FixedBase') is not null drop table warehouse.insightarchive.SalesVisSuite_FixedBase

END
