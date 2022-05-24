CREATE PROCEDURE insightarchive.salespack_storepostcodes @brandid int
AS

delete from Warehouse.insightarchive.Salespack_store_postcodes
	where main_brand = (select BrandName from Relational.Brand where BrandID =@brandid);


--------------------------------------------------
-- STORE LOCATIONS
--------------------------------------------------
insert into Warehouse.insightarchive.Salespack_store_postcodes
select pc.postcode
	,BrandName as main_brand
	,IsOnline
	,sum(amount) as spend
	,count(*) as transactions
	,count(distinct cinid) as customers
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join Warehouse.Relational.ConsumerCombination cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
join Warehouse.Relational.Brand B on cc.BrandID = b.BrandID
join Warehouse.AWSFile.ComboPostCode pc  on pc.ConsumerCombinationID = cc.ConsumerCombinationID
where cc.BrandID = @brandid
and trandate >= dateadd(month,-12,getdate())
group by pc.postcode
	,BrandName
	,IsOnline