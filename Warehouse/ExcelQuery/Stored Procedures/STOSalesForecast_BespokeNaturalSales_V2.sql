
/*=================================================================================================
Uploading the Data from Excel
Part 1: Running Bespoke Natural Sales
Version 1: 
=================================================================================================*/


CREATE PROCEDURE [ExcelQuery].[STOSalesForecast_BespokeNaturalSales_V2] 
WITH EXECUTE AS OWNER
AS


if object_id('tempdb..#outputsummary') is not null drop table #outputsummary
create table #outputsummary ( CustomerType varchar(50) NULL
							 ,counts int null
							,avgw_sales money null
							,avgw_spder real null )


--if object_id('tempdb..#BespokeSegment_NaturalSales') is not null drop table #BespokeSegment_NaturalSales
--create table #BespokeSegment_NaturalSales (brandid int null
--                            ,CustomerType varchar(50) NULL
--							 ,counts int null
--							,avgw_sales money null
--							,avgw_spder real null )




-------------------------------------------------------------------------
--- Dates : 
------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#weekbuild') IS NOT NULL DROP TABLE #weekbuild
select *
,row_number () over (order by startdate) as Weekno
into #weekbuild
from (
select weeknum
,min(startdate) as startdate
,max(enddate) as enddate
from Warehouse.InsightArchive.STOSalesForecast_Rundaylk 
where buildweek=1
group by weeknum ) a

-------------------------------------------------------------------------
---BASE
------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#Activated_HM') IS NOT NULL DROP TABLE #Activated_HM
select a.*
,lk2.comboID as ComboID_2 -- Gender / Age group and Cameo grp
into #Activated_HM
from Warehouse.InsightArchive.STOSalesForecast_Base a  -- full base
left join Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool lk2 on a.gender=lk2.gender and a.CAMEO_CODE_GRP=lk2.CAMEO_grp and a.Age_Group=lk2.Age_Group

--CREATE INDEX IND_Cins on #Activated_HM(CINID);

----  The main code  (campaign heatmap) set index to 100 for all those unknown
----  In main code (campaign heatmap) I think missing is just set to 0 (so excluded).  


----------------------------------------------------------------------------
--- The Subset of the Cardholders

IF OBJECT_ID('tempdb..#SubSet') IS NOT NULL DROP TABLE #SubSet
select a.*
into #SubSet
from #Activated_HM a  -- full base
inner join Warehouse.ExcelQuery.STOSalesForecast_BespokeInputCameo bc on bc.CAMEO_GRP_CODE=a.CAMEO_CODE_GRP  -- ADD THE REST WHEN ON MAIN!
inner join Warehouse.ExcelQuery.STOSalesForecast_BespokeInputRegion r on r.region=a.Region
inner join Warehouse.ExcelQuery.STOSalesForecast_BespokeInputGender g on g.gender=a.Gender
inner join Warehouse.ExcelQuery.STOSalesForecast_BespokeInputAgeGroup ag on ag.Age_Group=a.Age_Group

-- 8 seconds
--select top 10 * from Warehouse.ExcelQuery.STOSalesForecast_BespokeInputAgeGroup

declare @brandid int
set @brandid = (select brandid from Warehouse.ExcelQuery.STOSalesForecast_BespokeInputOther)
print @brandid

-- Adding the heatmap response score
---- Storing this data out as a permanent so that in the check results I can see which demographics where created

--IF OBJECT_ID('ExcelQuery.STOSales_BespokeCustomers') IS NOT NULL DROP TABLE ExcelQuery.STOSales_BespokeCustomers
truncate table Warehouse.ExcelQuery.STOSales_BespokeCustomers;
insert into Warehouse.ExcelQuery.STOSales_BespokeCustomers
select a.*
,hi.Index_RR
from #SubSet a  -- full base
inner join Warehouse.InsightArchive.SalesSTO_HeatmapBrandCombo_Index hi on hi.ComboID_2=a.ComboID_2  -- CHANGE NAME WHEN COPY COMPLETE
where hi.brandid =@brandid

--CREATE INDEX IND_Cin on ExcelQuery.STOSales_BespokeCustomers(CINID);


------------------------------------------------------------------------
---------- Getting CombinationsID for Brand and Competitors
------------------------------------------------------------------------


IF OBJECT_ID('tempdb..#ccids') IS NOT NULL DROP TABLE #ccids
select  distinct ConsumerCombinationID
       ,cc.BrandID
into #ccids 
from Warehouse.Relational.ConsumerCombination cc
where cc.BrandID=@brandid 
and IsUKSpend = 1

CREATE INDEX IND_CC on #ccids(ConsumerCombinationID);

------------------------------------------------
---------  Defining the Sector -----------------
------------------------------------------------
-- select top 10 * from Warehouse.InsightArchive.STOSalesForecast_SectorSpders


If object_id('tempdb..#SectorSpender') is not null drop table #SectorSpender ;
create table #SectorSpender (CINID INT NULL
					    ,SectorSpender INT NULL )


If object_id('tempdb..#SectorCCs') is not null drop table #SectorCCs ;
create table #SectorCCs ( ConsumerCombinationID INT NULL
							 ,BrandID INT NULL
							,BrandName VARCHAR(50) NULL )



 IF (Select count(1) from Warehouse.ExcelQuery.STOSalesForecast_BespokeCompetitors where Brandid is not NULL) >=1
   BEGIN
   Print 'Bespoke Competitor List'
			Insert into #SectorCCs
			select cc.ConsumerCombinationID
			,cc.BrandID
			,br.BrandName
			from warehouse.relational.ConsumerCombination cc with (nolock)
			inner join Warehouse.Relational.Brand br on br.BrandID=cc.BrandID -- The full brand list and name
			inner join Warehouse.ExcelQuery.STOSalesForecast_BespokeCompetitors bc on bc.brandID=br.brandid -- fix the input
			and isUKspend = 1

-- and Pull the transactions
			declare @extractS_S date    , @extractA_S date ,  @ALengS int 
			set @extractS_S = (select dateadd(day,-1,min(linedate)) from Warehouse.InsightArchive.STOSalesForecast_rundaylk where buildweek = 1)
			set @ALengS= (select ALeng from ExcelQuery.STOSalesForecast_BespokeInputOther )  

			set @extractA_S = dateadd(day,1,dateadd(month,-@ALengS,@extractS_S))  -- need this to be a dynamic range depending on brand
			print  @extractS_S 
			print @extractA_S


			insert into #SectorSpender
				select ct.CINID
				,1 as SectorSpender
			--	,@SectorID as SectorID 
					  --- issue is that this needs to include all sectors Ideally shouuld be dynamic but for now leave 
				from #SectorCCs b 
				inner join Warehouse.Relational.ConsumerTransaction ct with (nolock) on b.ConsumerCombinationID=ct.ConsumerCombinationID
				inner join warehouse.InsightArchive.STOSalesForecast_Base c on c.cinid=ct.cinid
				where TranDate between @extractA_S  and @extractS_S
				AND ISRefund = 0 --- exclude refunds
				group by ct.cinid


   END
    ELSE 
	BEGIN
 print 'Standard Out of Sector'

			declare @SectorID int
			set @SectorID = (select distinct sectorID from warehouse.InsightArchive.STOSalesForecast_Brands  where brandid=@brandid)
			print @SectorID

			Insert into #SectorSpender
             select cinid , SectorSpender
			 from Warehouse.InsightArchive.STOSalesForecast_SectorSpders
			 where SectorID = @SectorID
    END


------------------------------------------------------------
---------- Build Natural Counts data
-- Forecast data is the latest 4 weeks (of a full month)
------------------------------------------------------------

--select distinct AcquireL , lapserL from #brand
-- 5 current definiations of acquire and laspers
-- current approach would be 5 transactional pulls to define each
--- To save time could consider spliting into several queries not sure what is quicker here there are 5 combinations
--- 
-- Spliting as I don't want to have to get 24 months of grocery transactions for big 4 when I only need 3
-- but do get 6 


--select top 1000 * from Warehouse.InsightArchive.STOSalesForecast_rundaylk where buildweek = 1 order by linedate

declare @extractS date    , @extractA date , @extractL date , @ALeng int , @LLeng int 
set @extractS = (select dateadd(day,-1,min(linedate)) from Warehouse.InsightArchive.STOSalesForecast_rundaylk where buildweek = 1)
set @ALeng= (select ALeng from ExcelQuery.STOSalesForecast_BespokeInputOther )  
set @LLeng=(select LLeng from ExcelQuery.STOSalesForecast_BespokeInputOther)  

set @extractA = dateadd(day,1,dateadd(month,-@ALeng,@extractS))  -- need this to be a dynamic range depending on brand
set @extractL = dateadd(day,1,dateadd(month,-@LLeng,@extractS))
print  @extractS 
print @extractA
print @extractL

--print  @extractE 

---------- Extracting the date base date frame
---------- 
IF OBJECT_ID('tempdb..#currentSpend') IS NOT NULL DROP TABLE #currentSpend

(select ct.CINID
      ,BrandID
	  ,max(case when trandate between @extractA and @extractS then 1 else NULL end) as SpderA
	  ,max(case when trandate between @extractL and @extractS then 1 else NULL end) as SpderL
	  --- issue is that this start list could be dynamic! Limit to 14 currently. 
into #currentSpend
from #ccids b 
inner join Warehouse.Relational.ConsumerTransaction ct on b.ConsumerCombinationID=ct.ConsumerCombinationID
inner join ExcelQuery.STOSales_BespokeCustomers c on c.cinid=ct.cinid    ---- ON THE SUBSET OF DATA
where TranDate between @extractA and @extractS
AND ISRefund = 0 --- exclude refunds
and b.brandID =  @brandid -- building with single brand  
group by ct.cinid, BrandID
)



------------------------------------------  For the Sector Transactions
--IF OBJECT_ID('tempdb..#sectorCSpend') IS NOT NULL DROP TABLE #sectorCSpend

--(select ct.CINID
--	  ,1 as Sect_Spder

--into #sectorCSpend
--from #SectorCCs b 
--inner join Warehouse.Relational.ConsumerTransaction ct with (nolock) on b.ConsumerCombinationID=ct.ConsumerCombinationID
--inner join Warehouse.ExcelQuery.STOSales_BespokeCustomers c on c.cinid=ct.cinid    ---- ON THE SUBSET OF DATA
--where TranDate between @extractA and @extractS
--AND ISRefund = 0 --- exclude refunds
--group by ct.cinid, BrandID
--)



declare @Heatmap int
set @Heatmap = (select heatmap from ExcelQuery.STOSalesForecast_BespokeInputOther)

IF OBJECT_ID('tempdb..#Universe_STB') IS NOT NULL DROP TABLE #Universe_STB

select c.*
-- Full (emailable base) -- Acquire -- Lapser -- existing (remaining) -- Acquire and Heatmap
-- Needs to have the bespoke coding of the  customers
     ,case when s.SpderA is NULL then 1 else NULL end as Acquire
	 ,case when s.SpderL is NULL and s.SpderA=1 then 1 else NULL end as Lapser
	 ,case when s.SpderL is not NULL then 1 else NULL end as Existing
	 ,1 as Emailbase
------ The Acquire Universe : Heatmap : Hardcoded to 80
    ,case when s.SpderA is NULL and Index_RR>=@Heatmap then 1 else NULL end as Acquire_HM   -- Need to check what is happeding to low volumes 

     ,case when s.SpderA is Null and ss.SectorSpender is not null then 1 else NULL end as Acquire_InSector  --
     ,case when s.SpderA is Null and ss.SectorSpender  is null then 1 else NULL end as Acquire_OutofSector  --
     ,case when s.SpderA is Null and ss.SectorSpender  is null and Index_RR>=@Heatmap  then 1 else NULL end as Acquire_OutofSector_HM  --

into #Universe_STB
from ExcelQuery.STOSales_BespokeCustomers c    --- ON THE SEGMENT SUBSET!!!
left join #currentSpend s on c.CINID=s.CINID
left join #SectorSpender ss on c.CINID=ss.CINID

--select count(distinct cinid) from #SectorSpender

-- select count(1), count(distinct cinid),Acquire, Lapser , Existing, Acquire_HM  from #universe group by Acquire, Lapser , Existing, Acquire_HM


--select top 100 * from #cins_hm
----   Strip this out as only have 5 fixed universes so could just create this table at set up... Although still need loop
if object_id('tempdb..#CustTypeList') is not null drop table #CustTypeList

select c.Name as CustTypeLabel --from tempdb.sys.objects
into #CustTypeList
from tempdb.sys.tables as t
inner join tempdb.sys.columns as c
       on t.object_id = c.object_id
Where Left(t.name,14) ='#Universe_STB' +CHAR(95) and c.name not in (

select c.Name as ColumnName --from tempdb.sys.objects
from tempdb.sys.tables as t
inner join tempdb.sys.columns as c
       on t.object_id = c.object_id
Where t.name like '%cins_%' or t.name like '%CurrentSpend%' or t.name like '%ForecastSpend%'
or t.name like '%Activated_HM2%' or t.name like '%subset%' 
)

--- Might be able to cut this into fixed list at the beginning since it is a static read
if object_id('tempdb..#CustTypeList2') is not null drop table #CustTypeList2
SELECT * 
,row_number() over(order by CustTypeLabel) as seq
into #CustTypeList2
FROM #CustTypeList
where CustTypeLabel not in ('Index_RR')  -- must be a better way to do this!


---------- Extracting the date base date frame
declare  @extractE date
set @extractE = (select max(linedate) from Warehouse.InsightArchive.STOSalesForecast_rundaylk where buildweek = 1)
print @extractE
print dateadd(day,1,@extractS)


IF OBJECT_ID('tempdb..#ForecastSpend') IS NOT NULL DROP TABLE #ForecastSpend
select ct.CINID
      ,BrandID
	  ,sum(amount) as sales
	  ,TranDate
	into #ForecastSpend
from #ccids b 
inner join Warehouse.Relational.ConsumerTransaction ct on b.ConsumerCombinationID=ct.ConsumerCombinationID
inner join Warehouse.InsightArchive.STOSalesForecast_Base c on c.cinid=ct.cinid
where TranDate between dateadd(day,1,@extractS) and @extractE
and b.brandID = @brandid -- building with single brand  -- Prezzo 
AND ISRefund = 0 --- exclude refunds
group by ct.cinid, BrandID , TranDate



---- Add reference dates
----------------------------------------

IF OBJECT_ID('tempdb..#ForecastSpend2') IS NOT NULL DROP TABLE #ForecastSpend2
select t.*
,w.Weekno
into #ForecastSpend2
 from #ForecastSpend t 
cross join #weekbuild w
where t.trandate between w.startdate and w.enddate


--------------------------------------------------------------
---- Loop code to run for variousuniverse -- not using a group by as when I do heatmap there will be overlapping customers
---------------------------------
--select * from #CustTypeList2
--- WHY DOES THE CODE FAIL FOR NOT DELETING THE TABLE! 

DECLARE @seq tinyint, @SQL varchar(8000), @varname varchar(50), @base real
set @seq = 1
WHILE @seq IS NOT NULL
BEGIN


	SELECT @varname = Custtypelabel FROM #CustTypeList2 WHERE seq = @seq
	set @base = cast((select count(distinct cinid) from #Universe_STB ) as real)
	declare @noweeks real
    set @noweeks = (select max(weekno) from #weekbuild)
	SET @SQL = '

select 
''' +@varname+ ''' as customertype
,sum(sales) / '+cast(@noweeks as varchar)+' as avgw_Sales
,sum(spender)/ '+cast(@noweeks as varchar)+' as avgw_spder
into #forecastout
from (
select weekno
,sum(sales) as sales
,count(distinct t.cinid) as spender
from #Universe_STB b
inner join #ForecastSpend2 t on b.cinid=t.CINID
where '+@varname+'=1    
group by weekno ) a

select 
'''+@varname+''' as Customertype
,count(distinct cinid) as cardholders
into #countsout
from #Universe_STB
where '+@varname+'=1    

--- Joining the table to get outputs
select c.*
,f.avgw_Sales
,f.avgw_spder
into #outall
from #countsout c
left join #forecastout f on c.Customertype=f.Customertype


insert into #outputsummary
select *
from #outall'

--print(@sql)
exec( @sql)
	SELECT @seq = MIN(seq) FROM #CustTypeList2 WHERE seq >@seq

END

--- 

-------------------------------------------------------------------------------------------------------------
------   4. Getting the final outputs
-- here opting for 4 week average to scale
------------------------------------------------------------------------------

---- NEED TO PUSH THROUGH TO EXCEL SOLUTION OUTPUT

--SELECT 'Copy below results to columns B end of data in sheet Natural Sales' Instructions

declare @basetotal real
set @basetotal = (select count(distinct cinid) from Warehouse.InsightArchive.STOSalesForecast_Base) 
declare @name varchar(200)
set @name = (select Segmentname from ExcelQuery.STOSalesForecast_BespokeInputOther)                 -- select * from   MAKE THE INPUT NAME
--declare @brandID2 int
--set @brandID2 = (select BrandID from ExcelQuery.STOSalesForecast_BespokeInputOther) 

--IF OBJECT_ID('ExcelQuery.STOSales_BespokeNaturalSales') IS NOT NULL DROP TABLE ExcelQuery.STOSales_BespokeNaturalSales
truncate table ExcelQuery.STOSales_BespokeNaturalSales;
insert into ExcelQuery.STOSales_BespokeNaturalSales
select distinct a.brandid
,b.brandname
,a.customer_type
,counts
,base
,SPC1_avg
,RR1_avg
,a.AcquireL
,a.LapserL
from (
select @brandID as brandid 
,CustomerType + '_'+  @name as customer_type
,counts
,@basetotal as base
,avgw_sales/counts as SPC1_avg 
,avgw_spder/counts as RR1_avg
--,o.avgw_sales / o.avgw_spder as avgSPS
,@ALeng AcquireL
,@LLeng  LapserL
from #outputsummary ) a
inner join Warehouse.InsightArchive.STOSalesForecast_Brands b on a.brandid=b.BrandID

--select * from #outputsummary

------  OUTPUT FOR Names
truncate table ExcelQuery.STOSales_BespokeCustomerGroups;
insert into ExcelQuery.STOSales_BespokeCustomerGroups
select distinct customer_type from ExcelQuery.STOSales_BespokeNaturalSales








-----  TRUNCATE THE BESPOKE CREATION TABLES
--select top 100 * from ExcelQuery.STOSales_BespokeNaturalSales


-- Validation of Evan Cycles and competitor run
-- select * from #weekbuild
----  Check they are acquire not spent in the last 12 months

--select *
--from #universe_STB C
--where C.cinid in (
--	select distinct ct.cinid
--	from warehouse.relational.ConsumerTransaction ct
--	inner join #universe_STB c on c.CINID=ct.CINID
--	inner join warehouse.relational.ConsumerCombination cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
--	where TranDate between '2015-01-04' and '2016-01-03'
--	and cc.BrandID = 149
--	and c.Acquire_InSector=1 
--	AND ISRefund = 0 ) 
--AND  Acquire_InSector=1

---- ok

----- They are spend in the competitors
--select *
--from #universe_STB C
--where C.cinid not in (
--	select distinct ct.cinid
--	from warehouse.relational.ConsumerTransaction ct
--	inner join #universe_STB c on c.CINID=ct.CINID
--	inner join warehouse.relational.ConsumerCombination cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
--	where TranDate between '2015-01-04' and '2016-01-03'
--	and cc.BrandID in (499,1410,111,1907,1906,190)
--	and c.Acquire_InSector=1 
--	AND ISRefund = 0 ) 
--AND  Acquire_InSector=1

---- ok

----- Check the out of sector is out of sector

--select *
--from #universe_STB C
--where C.cinid in (
--	select distinct ct.cinid
--	from warehouse.relational.ConsumerTransaction ct
--	inner join #universe_STB c on c.CINID=ct.CINID
--	inner join warehouse.relational.ConsumerCombination cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
--	where TranDate between '2015-01-04' and '2016-01-03'
--	and cc.BrandID = 149
--	and c.Acquire_OutofSector=1 
--	AND ISRefund = 0 ) 
--AND  Acquire_OutofSector=1


--select *
--from #universe_STB C
--where C.cinid  in (
--	select distinct ct.cinid
--	from warehouse.relational.ConsumerTransaction ct
--	inner join #universe_STB c on c.CINID=ct.CINID
--	inner join warehouse.relational.ConsumerCombination cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
--	where TranDate between '2015-01-04' and '2016-01-03'
--	and cc.BrandID in (499,1410,111,1907,1906,190)
--	and c.Acquire_OutofSector=1 
--	AND ISRefund = 0 ) 
--AND  Acquire_OutofSector=1


----- Run for the sector as standard and OK 



---------  Validation what did those in the Westmidlands and Scotland spend last year April to June

----select fanid
----,cinid
----,Region
----into #CustChk
----from warehouse.relational.Customer c
----inner join warehouse.relational.cinlist cl on c.sourceUID=cl.CIN
----where currentlyActive=1 and MarketableByEmail=1


----IF OBJECT_ID('tempdb..#ccidsChk') IS NOT NULL DROP TABLE #ccidsChk
----select  distinct ConsumerCombinationID
----       ,cc.BrandID
----into #ccidsChk
----from Warehouse.Relational.ConsumerCombination cc
----where cc.BrandID=655
----and IsUKSpend = 1
------and bi.rowno between 225 and 250 -- limiting to 25 for testing code process

----CREATE INDEX INDCC on #ccidsChk(ConsumerCombinationID);

----select sum(amount) as sales
----,count(distinct ct.cinid) as spenders
----from warehouse.relational.ConsumerTransaction ct
----inner join #CustChk c on c.CINID=ct.CINID
----inner join #ccidsChk b on b.ConsumerCombinationID=ct.ConsumerCombinationID
----where TranDate between '2015-04-02' and '2015-06-24'
----and region in ('WEST MIDLANDS','SCOTLAND')



----select count(distinct cinid) from #CustChk where region in ('WEST MIDLANDS','SCOTLAND')
----select distinct region from #CustChk