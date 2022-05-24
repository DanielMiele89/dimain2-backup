CREATE PROCEDURE insightarchive.salespack_demographic_profiling_sp @main_brand_id int
AS

delete from Warehouse.insightarchive.Salespack_Demographic_profiling
	where main_brand = (select BrandName from Relational.Brand where BrandID =@main_brand_id);



IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
select ConsumerCombinationID,BrandName
into #CC 
FROM Warehouse.RELATIONAL.ConsumerCombination A
join Warehouse.RELATIONAL.Brand b on a.BrandID =b.BrandID
where a.BrandID = @main_brand_id 




IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB;
SELECT (select brandname from Warehouse.RELATIONAL.brand where brandid = @main_brand_id) as main_brand
	,C.AgeCurrentBandText
	,C.Region
	,C.Gender
	,F.CAMEO_CODE_GROUP_Category
	,F.Social_Class
	,COUNT(*) AS TOTAL_COUNT
into #fb
FROM Warehouse.RELATIONAL.Customer C
JOIN Warehouse.RELATIONAL.CAMEO D ON D.Postcode = C.PostCode
JOIN Warehouse.RELATIONAL.CAMEO_CODE E ON E.CAMEO_CODE = D.CAMEO_CODE
JOIN Warehouse.RELATIONAL.CAMEO_CODE_GROUP F ON E.CAMEO_CODE_GROUP = F.CAMEO_CODE_GROUP
where CurrentlyActive = 1
and AgeCurrentBandText <> 'Unknown' 
and Gender <> 'U'
AND CAMEO_CODE_GROUP_Category <> 'Communal Establishments'
AND f.Social_Class <> 'NULL'

GROUP BY C.AgeCurrentBandText
	,C.Region
	,C.Gender
	,F.CAMEO_CODE_GROUP_Category
	,F.Social_Class;





IF OBJECT_ID('tempdb..#ct') IS NOT NULL DROP TABLE #ct;
SELECT #cc.BrandName
	,C.AgeCurrentBandText
	,C.Region
	,C.Gender
	,F.CAMEO_CODE_GROUP_Category
	,F.Social_Class
	,count(distinct ct.cinid) as brand_customers
into #CT
FROM Warehouse.RELATIONAL.ConsumerTransaction_MyRewards CT
JOIN #CC ON #CC.ConsumerCombinationID = CT.ConsumerCombinationID
JOIN Warehouse.RELATIONAL.CINList CINLIST ON CINLIST.CINID = CT.CINID
JOIN Warehouse.RELATIONAL.Customer C ON C.SourceUID = CINLIST.CIN
JOIN Warehouse.RELATIONAL.CAMEO D ON D.Postcode = C.PostCode
JOIN Warehouse.RELATIONAL.CAMEO_CODE E ON E.CAMEO_CODE = D.CAMEO_CODE
JOIN Warehouse.RELATIONAL.CAMEO_CODE_GROUP F ON E.CAMEO_CODE_GROUP = F.CAMEO_CODE_GROUP
WHERE AMOUNT>0
AND		c.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
and trandate >= dateadd(month,-12,getdate())
group by #cc.BrandName
	,C.AgeCurrentBandText
	,C.Region
	,C.Gender
	,F.CAMEO_CODE_GROUP_Category
	,F.Social_Class
	

	insert into Warehouse.insightarchive.Salespack_Demographic_profiling
select 
		(select brandname from Warehouse.RELATIONAL.brand where brandid = @main_brand_id) as main_brand
		,a.AgeCurrentBandText
		,a.CAMEO_CODE_GROUP_Category
		,a.Region
		,a.Gender
		,a.Social_Class
		,TOTAL_COUNT
		,case when brand_customers is null then 0 else brand_customers end as brand_customers
from #fb a
left join #ct b on a.AgeCurrentBandText = b.AgeCurrentBandText 
				and a.region = b.region
				and a.Gender = b.Gender
				and a.CAMEO_CODE_GROUP_Category = b.CAMEO_CODE_GROUP_Category
				and a.Social_Class = b.Social_Class

