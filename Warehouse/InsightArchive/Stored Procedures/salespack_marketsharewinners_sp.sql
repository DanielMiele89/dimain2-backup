CREATE PROCEDURE insightarchive.salespack_marketsharewinners_sp @main_brand_id int,
@firstbrandid int,
@secondbrandid int,
@thirdbrandid int,
@forthbrandid int,
@fifthbrandid int,
@sixthbrandid int,
@seventhtbrandid int,
@eighthbrandid int

AS

delete from Warehouse.insightarchive.Salespack_Market_share_winners
	where main_brand = (select BrandName from Relational.Brand where BrandID =@main_brand_id);

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
select ConsumerCombinationID,BrandName, SectorName, GroupName
into #CC 
FROM Relational.ConsumerCombination A
join Relational.Brand b on a.BrandID =b.BrandID
JOIN Relational.BrandSector S ON S.SectorID = B.SectorID
JOIN Relational.BrandSectorGroup SG ON SG.SectorGroupID = S.SectorGroupID
where a.BrandID in (@main_brand_id,
@firstbrandid,
@secondbrandid,
@thirdbrandid,
@forthbrandid,
@fifthbrandid,
@sixthbrandid,
@seventhtbrandid,
@eighthbrandid)



IF OBJECT_ID('tempdb..#ct') IS NOT NULL DROP TABLE #ct;
SELECT region
	--,postcode
	--,PostalSector
	--,PostArea
	,PostCodeDistrict
	,cc.BrandName
	,cast(DATEADD(month, DATEDIFF(month, 0, trandate), 0) as date) AS month_commencing
	,sum(CT.AMOUNT) as amount
into #CT
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CC cc ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
JOIN Relational.CINList CINLIST ON CINLIST.CINID = CT.CINID
JOIN Relational.Customer C ON C.SourceUID = CINLIST.CIN
WHERE AMOUNT>0
AND		c.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
and (trandate >= dateadd(month,-13,getdate()))
and region is not null
group by region
	--,postcode
	--,PostalSector
	--,PostArea
	,PostCodeDistrict
	,cc.BrandName
	,cast(DATEADD(month, DATEDIFF(month, 0, trandate), 0) as date)



-----calculate marketshare per region 
IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1;
select  region
	--,postcode
	--,PostalSector
	--,PostArea
	,PostCodeDistrict
	,brandname
	,month_commencing 
	,amount / sum(amount) over (partition by region, month_commencing,postcodedistrict) as market_share
	,amount
into #temp1
from #ct


--- rank per region 
IF OBJECT_ID('tempdb..#temp2') IS NOT NULL DROP TABLE #temp2;
select *
	, ROW_NUMBER() over(partition by region, month_commencing,postcodedistrict order by market_share desc) as ranking
into #temp2
from #temp1


insert into Warehouse.insightarchive.Salespack_Market_share_winners
select (select brandname from warehouse.relational.brand where brandid=@main_brand_id) as Main_brand
	, region
	--,postcode
	--,PostalSector
	--,PostArea
	,PostCodeDistrict
	, BrandName
	, month_commencing
	, amount
	, market_share
	, ranking
from #temp2 
