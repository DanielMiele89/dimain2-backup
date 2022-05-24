CREATE PROCEDURE insightarchive.salespack_brandaffinity_sp @main_brand_id int
AS

delete from Warehouse.insightarchive.Salespack_Brandaffinity
where main_brand = (select BrandName from Relational.Brand where BrandID =@main_brand_id);

declare @START_PERIOD DATE =  convert(date,dateadd(month,-12,getdate())) -- '2020-01-01'
declare @END_PERIOD DATE = convert(date,GETDATE()) --'2021-01-01'

----------------------------------------------------------------------------------
-- DEBIT CARD get everyone who made a transaction in the last 12m and the brand -- 
----------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#last_12m_shoppers') IS NOT NULL DROP TABLE #last_12m_shoppers
select cinid	
	,brandname
	,br.BrandID
	,SectorName
	,GroupName 
into #last_12m_shoppers
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
with (index(ix_STUFF01))
join Warehouse.Relational.ConsumerCombination cc on ct.ConsumerCombinationID = cc.ConsumerCombinationID
join Warehouse.Relational.Brand br on cc.BrandID = br.BrandID
join Warehouse.Relational.BrandSector s on s.SectorID = br.SectorID
join Warehouse.Relational.BrandSectorGroup SG on sg.SectorGroupID = s.SectorGroupID
where TranDate BETWEEN @START_PERIOD AND @END_PERIOD
and amount > 0
group by cinid, BrandName,br.BrandID, SectorName,GroupName



declare @total_base int = (select count(distinct CINID) from #last_12m_shoppers)
declare @total_brand int = (select count(distinct CINID) from #last_12m_shoppers where BrandID = @main_brand_id)

--- full base
IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1
select brandname
	,BrandID
	,SectorName
	,GroupName
	,count(*) as customers
into #temp1
from #last_12m_shoppers
group by BrandName
	,BrandID
	,SectorName
	,GroupName

IF OBJECT_ID('tempdb..#FBaffinity') IS NOT NULL DROP TABLE #FBaffinity
select brandname
	,cast(customers as float)/cast(@total_base as float) as percentage_customers
	,SectorName
	,GroupName
into #FBaffinity
from #temp1


---- aggregation
IF OBJECT_ID('tempdb..#agg') IS NOT NULL DROP TABLE #agg
select BrandName
	,cast(count(distinct cinid) as float) / cast (@total_brand as float) as ratio
into #agg
from #last_12m_shoppers 
where cinid in (select cinid from #last_12m_shoppers  where BrandID = @main_brand_id)
group by BrandName

insert into Warehouse.insightarchive.Salespack_Brandaffinity
--- final indexing
select (select BrandName from Warehouse.Relational.brand where brandid	= @main_brand_id) as main_brand
	,b.BrandName as main_brand
	,SectorName
	,GroupName
	,b.ratio as brand_ratio
	,a.percentage_customers as fullbase_ratio
from #FBaffinity a
join #agg b on a.brandname = b.brandname