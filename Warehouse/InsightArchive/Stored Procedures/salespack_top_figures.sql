CREATE PROCEDURE insightarchive.salespack_top_figures @brandid int
AS

delete from Warehouse.insightarchive.salespack_top_level_figures
where brandname = (select BrandName from Relational.Brand where BrandID =@brandid);
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
--MY REWARDS
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
declare @RBScardholders int = (select count(*) FROM warehouse.Relational.Customer C where CurrentlyActive = 1)

insert into Warehouse.insightarchive.salespack_top_level_figures
select BrandName
	,IsOnline
	,count(*) as transactions
	,count(distinct cinid) as customers
	,sum(amount) as Spend
	,@RBScardholders as fb
	,'MY REWARDS DATA' as type
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join Warehouse.Relational.ConsumerCombination cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
join Warehouse.Relational.Brand B on cc.BrandID = b.BrandID

where cc.BrandID = @brandid
and trandate >= dateadd(month,-12,getdate())
and amount > 0
group by brandname, IsOnline

union

select BrandName as main_brand
	,2 as IsOnline
	,count(*) as transactions
	,count(distinct cinid) as customers
	,sum(amount) as Spend
	,@RBScardholders as fb
	,'MY REWARDS DATA' as type
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join Warehouse.Relational.ConsumerCombination cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
join Warehouse.Relational.Brand B on cc.BrandID = b.BrandID
where cc.BrandID = @brandid
and trandate >= dateadd(month,-12,getdate())
and amount > 0
group by brandname


-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
--BIG DATA 
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

declare @BIGDATAcardholders int = (select count(DISTINCT CINID) FROM warehouse.Relational.ConsumerTransaction where TRANDATE >= convert(date,DATEADD(MONTH,-3,GETDATE())))

insert into Warehouse.insightarchive.salespack_top_level_figures
select BrandName
	,IsOnline
	,count(*) as transactions
	,count(distinct cinid) as customers
	,sum(amount) as Spend
	,@BIGDATAcardholders as fb
	,'BIG DATA' as type
from Warehouse.Relational.ConsumerTransaction ct
join Warehouse.Relational.ConsumerCombination cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
join Warehouse.Relational.Brand B on cc.BrandID = b.BrandID
where cc.BrandID = @brandid
and trandate >= dateadd(month,-12,getdate())
and amount > 0
group by brandname, IsOnline

union

select BrandName as main_brand
	,2 as IsOnline
	,count(*) as transactions
	,count(distinct cinid) as customers
	,sum(amount) as Spend
	,@BIGDATAcardholders as fb
	,'BIG DATA' as type
from Warehouse.Relational.ConsumerTransaction cT
join Warehouse.Relational.ConsumerCombination cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
join Warehouse.Relational.Brand B on cc.BrandID = b.BrandID
where cc.BrandID = @brandid
and trandate >= dateadd(month,-12,getdate())
and amount > 0
group by brandname