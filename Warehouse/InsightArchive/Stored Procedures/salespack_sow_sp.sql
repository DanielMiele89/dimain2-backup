CREATE PROCEDURE insightarchive.salespack_sow_sp @sow_brand_id int,
@firstbrandid int,
@secondbrandid int,
@thirdbrandid int,
@forthbrandid int,
@fifthbrandid int,
@sixthbrandid int,
@seventhtbrandid int,
@eighthbrandid int

AS

-----------------------------------------------------------------------------------
-------use the ids to get relevant consumer combination ids
-----------------------------------------------------------------------------------
delete from Warehouse.insightarchive.Salespack_SOW
	where main_brand = (select BrandName from Relational.Brand where brandid =@sow_brand_id);

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
select ConsumerCombinationID,BrandName, SectorName, GroupName
into #CC 
FROM Relational.ConsumerCombination A
join Relational.Brand b on a.BrandID =b.BrandID
JOIN Relational.BrandSector S ON S.SectorID = B.SectorID
JOIN Relational.BrandSectorGroup SG ON SG.SectorGroupID = S.SectorGroupID
where a.BrandID in (@sow_brand_id,
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
SELECT CT.CINID
	,cc.BrandName
	,DATEADD(month, DATEDIFF(month, 0, CAST(trandate AS DATE)), 0) AS month_commencing
	,sum(CT.AMOUNT) as amount
	,count(*) as transactions
into #CT
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CC cc ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
JOIN Relational.CINList CINLIST ON CINLIST.CINID = CT.CINID
JOIN Relational.Customer C ON C.SourceUID = CINLIST.CIN
JOIN RELATIONAL.CAMEO D ON D.Postcode = C.PostCode
JOIN RELATIONAL.CAMEO_CODE E ON E.CAMEO_CODE = D.CAMEO_CODE
JOIN Relational.CAMEO_CODE_GROUP F ON E.CAMEO_CODE_GROUP = F.CAMEO_CODE_GROUP
WHERE AMOUNT>0
AND		c.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
and (trandate >= dateadd(month,-12,getdate()))
group by CT.CINID
	,cc.BrandName
	,DATEADD(month, DATEDIFF(month, 0, CAST(trandate AS DATE)), 0);


insert into Warehouse.insightarchive.Salespack_SOW
select (select brandname from relational.brand where brandid=@sow_brand_id) as main_brand
	,a.month_commencing
	,b.BrandName
	,sum(b.amount) as spend
	--into Warehouse.insightarchive.Salespack_SOW
from (select * from #CT where BrandName = (select brandname from relational.brand where brandid=@sow_brand_id)) a 
join #ct b on a.CINID = b.cinid and a.month_commencing = b.month_commencing
group by a.month_commencing
	,b.BrandName