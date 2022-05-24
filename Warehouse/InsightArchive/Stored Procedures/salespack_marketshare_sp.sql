CREATE PROCEDURE insightarchive.salespack_marketshare_sp @main_brand_id int,
@firstbrandid int,
@secondbrandid int,
@thirdbrandid int,
@forthbrandid int,
@fifthbrandid int,
@sixthbrandid int,
@seventhtbrandid int,
@eighthbrandid int

 as

delete from Warehouse.insightarchive.Salespack_Market_share
	where main_brand = (select BrandName from Relational.Brand where BrandID =@main_brand_id);

-----------------------------------------------------------------------------------
-------use the ids to get relevant consumer combination ids
-----------------------------------------------------------------------------------

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
@eighthbrandid) -----------------------INPUT BRANDS ---------------
--OR S.SectorID IN (1,2)	-----------------------INPUT SUB SECTOR ---------------
--OR SG.SectorGroupID IN (1,2)	-----------------------INPUT SECTOR ---------------

-----------------------------------------------------------------------------------
-------output one row per day per brand per channel (online/offline)
-----------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#ct') IS NOT NULL DROP TABLE #ct;
insert into Warehouse.insightarchive.Salespack_Market_share
SELECT (select brandname from relational.brand where brandid=@main_brand_id) as main_brand
	,cc.BrandName
	,DATEADD(month, DATEDIFF(month, 0, CAST(trandate AS DATE)), 0) AS month_commencing
	,sum(CT.AMOUNT) as amount
	,count(*) as transactions
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CC cc ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE AMOUNT>0
and (trandate >= dateadd(month,-12,getdate()))
group by cc.BrandName
	,DATEADD(month, DATEDIFF(month, 0, CAST(trandate AS DATE)), 0)