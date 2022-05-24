

/*=================================================================================================
Brand Correlation Refresh
Version 1: A. Devereux 25/02/2017
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[brand_correlation_refresh]
AS
BEGIN
	SET NOCOUNT ON;

----------------------------------------------------------------------------------------
----------  Setting Parameters
----------------------------------------------------------------------------------------

Declare		@Today			datetime,
			@time			DATETIME,
			@msg			VARCHAR(2048)



----------------------------------------------------------------------------------------
----------  Brands
----------------------------------------------------------------------------------------
if object_id('tempdb..#top500Brands') is not null drop table #top500Brands

select		top 500 b.BrandID, BrandName
into		#top500Brands
from		mi.TotalBrandSpend s
join		Relational.Brand b on b.BrandID=s.BrandID
order by	CustomerCountThisYear desc

if object_id('tempdb..#BrandsAddition') is not null drop table #BrandsAddition

select		BrandID, BrandName
into		#BrandsAddition
from		Relational.brand
where brandid in (7,1111,83,1010,1370,149,1759,156,166,170,197,199,1757,1079,1507,1084,1171,361,1458,450,480,1345,57,487,23,62,485,207,1360,1463,1001,1168,75,1122,303,331,379,414,1023,12,1622,1892,119,142,1729,188,190,1170,1435,260,869,463,6,68,193,283,305,309,391,454,475,1904,1908,1931,1571,2018,1570,2017,104,2319)

if object_id('tempdb..#Brands') is not null drop table #Brands

SELECT distinct *
  INTO  #Brands
FROM
(
        SELECT     *
    FROM         #top500Brands
    UNION
    SELECT     *
    FROM         #BrandsAddition
) bf
order by BrandName

if object_id('tempdb..#brandnames') is not null drop table #brandnames

select		*
into		#brandnames
from		#Brands
order by	BrandName


CREATE CLUSTERED INDEX ix_BID on #Brands(BrandID)


if object_id('tempdb..#cc') is not null drop table #cc

select		b.BrandID, consumercombinationid, BrandName
into		#cc
from		Relational.ConsumerCombination cc
join		#Brands b on b.brandID=cc.brandID

CREATE NONCLUSTERED INDEX ix_BID on #cc(BrandID)
CREATE CLUSTERED INDEX ix_BCID on #cc(consumercombinationid)

----------------------------------------------------------------------------------------
----------  Customer Base Splitting
----------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#cins') IS NOT NULL DROP TABLE #cins

CREATE TABLE #cins(
			CINID INT
		   ,RowNo INT
			)
INSERT into        #cins
Select      distinct top 1000000 CL.CINID, ROW_NUMBER() OVER(ORDER BY Newid() ASC) AS RowNo
From        warehouse.relational.customer c 
join        warehouse.Relational.CINList cl on c.SourceUID = cl.CIN
left join   Staging.Customer_DuplicateSourceUID dup on dup.sourceUID = c.SourceUID 
where       dup.sourceuid  is NULL
and         CurrentlyActive=1
and         MarketableByEmail=1


CREATE CLUSTERED INDEX ix_CINID on #cins(CINID)

----------------------------------------------------------------------------------------
----------  Spending
----------------------------------------------------------------------------------------

if object_id('tempdb..#spend') is not null drop table #spend

select		h.RowNo
			,h.CINID
			,cc.Brandname
			,count(amount) as Trans
into		#spend
from		Relational.ConsumerTransaction ct with (nolock)
join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
join		#cins h on h.CINID=ct.CINID
where		trandate between '2016-01-01' and '2016-12-31'
group by	h.CINID, cc.BrandName, h.RowNo

if object_id('tempdb..#spend_data') is not null drop table #spend_data
create table #spend_data
(
		CINID		int
		,Brandname	Varchar(Max)
		,Trans		int

)

Declare		@RowNo int, @MaxRowNo int,@Chunksize int

Set			@RowNo = 1
Set			@MaxRowNo = (Select count(*) From #spend)
Set			@Chunksize = 100000

While @RowNo <= @MaxRowNo
Begin
			insert into #spend_data

			select		CINID
						,BrandName
						,Trans
			from		#spend s
			where		s.RowNo Between @RowNo and @RowNo+(@ChunkSize-1)
	Set @RowNo = @RowNo+@Chunksize
End



DECLARE @BrandList NVARCHAR(MAX) = STUFF(( SELECT ',' + QUOTENAME(Brandname) FROM #brands order by brandname FOR XML PATH('')), 1, 1, '')

SET @BrandList = replace(@BrandList, 'amp;', '')

EXEC('

if object_id(''#spend_pivot'') is not null drop table #spend_pivot

select		*
into		#spend_pivot
from		#spend
pivot (
			sum(Trans) 
			FOR Brandname 
			in (' + @BrandList + ')
) x
ALTER TABLE #spend_pivot
DROP COLUMN RowNo

select * from #spend_pivot
')



end
