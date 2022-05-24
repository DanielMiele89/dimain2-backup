

/*=================================================================================================
Sales DRIVERS TO CHANGE
Version 1: A. Devereux 25/04/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 40 Minutes W/ Fixed Base; 20 Minutes W/O Fixed Base

CREATE PROCEDURE [Prototype].[SH_Drivers_to_Change]		(@Edate Date		--end date
															,@Brand int			--brand
															,@FBRequired int	--fixed base required (#TODO change to WETS fixed base)
															,@Reward int		--my rewards only
															,@onlineVariable bit)		--(All transactions:NULL, Online only:1, offline only:0)
AS
BEGIN
	SET NOCOUNT ON;
----------------------------------------------------------------------------------------
----------  SCRIPT: DRIVERS TO CHANGE
----------  AUTHOR: ALAN DEVEREUX
----------  Time:	Approx. 60 MINUTES (W/ FIXED BASE); 30 MINUTES (W/O FIXED BASE)
----------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
----------  Setting Parameters
----------------------------------------------------------------------------------------


Declare		@Today			datetime,
			@time			DATETIME,
			@msg			VARCHAR(2048)
Set			@Today			= getdate()


--Declare		@Edate			date
--Set			@Edate			= '2016-09-30'  -- SELECT THE LAST DAY IN THE LAST MONTH REQUIRED

--Declare		@Brand			int
--Set			@Brand			= 142			-- SELECT THE DESIRED MAIN BRAND
--									-- SELECT * FROM relational.brand where brandname like '%Jone%'

--Declare		@FBRequired		int			-- SET TO 1 IF AN UPDATED FIXED BASE IS REQUIRED
--Set			@FBRequired		= 0

--Declare		@Reward			int			-- SET TO 1 IF ONLY MY REWARDS CUSTOMERS ARE REQUIRED
--Set			@Reward			= 1

--Declare		@onlineVariable			int			-- SET TO 1 IF ONLY MY REWARDS CUSTOMERS ARE REQUIRED
--Set			@onlineVariable			= NULL

----------------------------------------------------------------------------------------
----------  CREATING APPROPRIATE DATE RANGES
----------------------------------------------------------------------------------------

	SELECT		@msg	= 'Create Dates Table'
	EXEC		warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
CREATE TABLE	#Dates	(Dates DATE NULL		 
						)

declare @EdateMonthStart date
set @EdateMonthStart = DATEADD(m, DATEDIFF(m, 0, @Edate), 0)

INSERT INTO		#Dates	VALUES	(@EdateMonthStart)

declare		@SDate	date
	set		@SDate	= (select dateadd(month,-37,@EdateMonthStart))

INSERT INTO		#Dates	VALUES	(@SDate)

select * from #dates

	
	SELECT @msg = 'Create #CalendarMonths Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

IF OBJECT_ID('tempdb..#Monthall') IS NOT NULL DROP TABLE #Monthall
					
;with MonthAll
as (Select @SDate as startdate
	UNION ALL
	Select DATEADD(m, 1, startdate)
	from MonthAll
	where startdate < DATEADD(m,-1,@Edate))



select startdate as m1
into #Monthall
from monthall
						
select * from #monthall


----------------------------------------------------------------------------------------
----------  CREATING APPROPRIATE DATE RANGES
----------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#CalendarMonths') IS NOT NULL DROP TABLE #CalendarMonths						
CREATE TABLE	#CalendarMonths (
					Rownum int
					,m1 DATE
					,m12 DATE
					,m24 DATE
					,PRIMARY KEY (m1)
								)


	SELECT @msg = 'Populate #CalendarMonths Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

DECLARE		@basedate	DATE,
			@offset		INT
						
SET			@basedate	= (select dateadd(month,-11,@EdateMonthStart))
SET			@offset		= 0

WHILE (@offset < 12)
	BEGIN
			INSERT INTO #CalendarMonths VALUES (
						@offset,
						dateadd(month,@offset,@basedate),
						dateadd(month,@offset-12,@basedate),
						dateadd(month,@offset-24,@basedate)
						)
			 --FROM #CalendarMonths
		SET @offset = @offset + 1
	END

select * from #calendarmonths

----------------------------------------------------------------------------------------
----------  Selecting Partner and Competitor With Consumer Combinations
----------------------------------------------------------------------------------------	
	SELECT @msg = 'Create  #PartnerList Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

IF OBJECT_ID('tempdb..#PartnerList') IS NOT NULL DROP TABLE #PartnerList

Create Table	#PartnerList
				(
				BrandID Int
				)
Insert Into #PartnerList Values (@Brand)

	SELECT @msg = 'Create  #competitorlist Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

IF OBJECT_ID('tempdb..#competitorlist') IS NOT NULL DROP TABLE #competitorlist

Select		competitorID	as BrandID
into		#competitorlist
from		relational.BrandCompetitor bc
join		#PartnerList p	on bc.BrandID = p.BrandID


CREATE NONCLUSTERED INDEX ix_BrandID on #competitorlist(BrandID)

	SELECT @msg = 'Create  #cc_partner Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#cc_partner') is not null drop table #cc_partner

select		b.brandid
			,ConsumerCombinationID
into		#cc_partner
from		#PartnerList b
inner join	relational.ConsumerCombination bm on b.brandid=bm.BrandID

CREATE CLUSTERED INDEX ix_brandID on #cc_partner(BrandID)
CREATE NONCLUSTERED INDEX ix_ccID on #cc_partner(ConsumerCombinationID)

	SELECT @msg = 'Create  #cc_competitor Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#cc_competitor') is not null drop table #cc_competitor

select		c.brandid
			,ConsumerCombinationID
into		#cc_competitor
from		#competitorlist c
inner join	relational.ConsumerCombination bm on c.brandid=bm.BrandID

CREATE CLUSTERED INDEX ix_brandID on #cc_competitor(BrandID)
CREATE NONCLUSTERED INDEX ix_ccID on #cc_competitor(ConsumerCombinationID)

----------------------------------------------------------------------------------------
----------  Creating the fixed base
----------------------------------------------------------------------------------------

if @FBRequired = 1		begin

						declare @fixedbasestartdate date 
							set @fixedbasestartdate = (select top 1 dates from #Dates order by dates asc)

						declare @fixedbaseenddate date 
							set @fixedbaseenddate = @edate

						select @fixedbasestartdate, @fixedbaseenddate

						if object_id('warehouse.insightarchive.alanDtC_fixedbase') is not null drop table warehouse.insightarchive.alanDtC_fixedbase
						EXEC Relational.CustomerBase_Generate 'alanDtC_fixedbase', @fixedbasestartdate, @fixedbaseenddate
						end

----------------------------------------------------------------------------------------
----------  Creating Customer List
----------------------------------------------------------------------------------------
if object_id('tempdb..#customerlist') is not null drop table #customerlist
CREATE TABLE #customerlist(
			CINID INT
			,RowNo INT Identity
			)

if @Reward = 0			begin

						
						INSERT into		#CustomerList
						SELECT		CINID
						from		warehouse.insightarchive.alanDtC_fixedbase

						end

if @Reward = 1			begin

					
						INSERT into		#CustomerList
						SELECT		fb.CINID
						from		warehouse.insightarchive.alanDtC_fixedbase fb
						inner join  Warehouse.Relational.CINList cl on fb.CINID = cl.CINID -- to get CINID
						inner join	Warehouse.Relational.Customer c on c.SourceUID = cl.CIN ---to get sourceuid
						end

CREATE CLUSTERED INDEX ix_CINID ON #CustomerList(CINID)

----------------------------------------------------------------------------------------
----------  Extracting Partner Spend
----------------------------------------------------------------------------------------


if object_id('tempdb..#Spend') is not null drop table #Spend
create table #Spend
(
		CINID		int
		,Amount		int
		,Trans		int
		,Month		date

)

DECLARE		@StartDate	DATE



SET			@StartDate	=	(SELECT Top 1 * FROM #Dates Order by dates asc)
Print @StartDate

Declare		@RowNo int, @MaxRowNo int,@Chunksize int

Set			@RowNo = 1
Set			@MaxRowNo = (Select Max(RowNo) From #CustomerList)
Set			@Chunksize = 100000

While @RowNo <= @MaxRowNo
Begin
			SELECT @msg = 'Populate Spend table - '+Cast(@RowNo as varchar)
			EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT
			insert into #Spend

			select		ct.CINID
						,sum(Amount) as Amount
						,count(1) as Trans
						,DATEADD(m, DATEDIFF(m, 0, ct.TranDate), 0)

			from		Relational.ConsumerTransaction ct with (nolock)
						inner join #CustomerList c on c.cinid=ct.cinid
						inner join #cc_partner b on b.ConsumerCombinationID=ct.ConsumerCombinationID

			where		ISRefund = 0 
						and c.RowNo Between @RowNo and @RowNo+(@ChunkSize-1) 
						and	(isonline = @onlineVariable or @onlineVariable IS NULL)
						and (ct.TranDate between @StartDate and @Edate)

			group by	ct.CINID
						,b.BrandID
						,DATEADD(m, DATEDIFF(m, 0, ct.TranDate), 0)

	Set @RowNo = @RowNo+@Chunksize
End

CREATE NONCLUSTERED INDEX ix_Month on #Spend(Month)
CREATE NONCLUSTERED INDEX ix_CINID on #Spend(CINID)



----------------------------------------------------------------------------------------
----------  Extracting Competitor Spend
----------------------------------------------------------------------------------------

if object_id('tempdb..#SpendC') is not null drop table #SpendC
create table #SpendC
(
		CINID		int
		,Flag		int
		,Month		Date
)

Declare		@RowNoC int, @MaxRowNoC int,@ChunksizeC int

Set			@RowNoC = 1
Set			@MaxRowNoC = (Select Max(RowNo) From #customerlist)
Set			@ChunksizeC = 100000

While @RowNoC <= @MaxRowNoC
		Begin
			SELECT @msg = 'Populate SpendC table - '+Cast(@RowNoC as varchar)
			EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT
			insert into #SpendC

			select	ct.cinid
					,1 as Flag
					,DATEADD(m, DATEDIFF(m, 0, ct.TranDate), 0)

			from relational.ConsumerTransaction ct with (nolock)
			inner join #CustomerList c on c.cinid=ct.cinid
			inner join #cc_competitor b on b.ConsumerCombinationID=ct.ConsumerCombinationID		

			where		ISRefund = 0 
						and c.RowNo Between @RowNoC and @RowNoC+(@ChunkSize-1) 
						and	(isonline = @onlineVariable or @onlineVariable IS NULL)
						and (ct.TranDate between @StartDate and @Edate)

			group by	ct.CINID
						,b.BrandID
						,DATEADD(m, DATEDIFF(m, 0, ct.TranDate), 0)

	print @RowNoC
	Set @RowNoC = @RowNoC+@ChunksizeC

End

CREATE NONCLUSTERED INDEX ix_Month on #SpendC(Month)
CREATE CLUSTERED INDEX ix_CINID on #SpendC(CINID)

----------------------------------------------------------------------------------------
----------  Aggregating Spend by Month and Customer Type
----------------------------------------------------------------------------------------
	
	SELECT @msg = 'Create  #Existing Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#Existing') is not null drop table #Existing
select	*
into #Existing
from (
select Month
		, sum(Amount) as Sales
		, sum(Trans) as Trans
		, count(distinct CINID) as Customers
from #CalendarMonths c
JOIN #Spend s on s.Month = c.m1
WHERE EXISTS (
	SELECT 1 FROM #Spend s2
	WHERE s2.CINID = s.CINID and s2.Month < c.m1 and s2.Month >= c.m12)
Group by Month

UNION

select	Month
		, sum(Amount) as Sales
		, sum(Trans) as Trans
		, count(distinct CINID) as Customers
from #CalendarMonths c
JOIN #Spend s on s.Month = c.m12
WHERE EXISTS (
	SELECT 1 FROM #Spend s2
	WHERE s2.CINID = s.CINID and s2.Month < c.m12 and s2.Month >= c.m24)
Group by Month
) as #Existing

	SELECT @msg = 'Create  #AcquireCS Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#AcquireCS') is not null drop table #AcquireCS
select *
into #AcquireCS
from (
select	Month
		, sum(Amount) as Sales
		, sum(Trans) as Trans
		, count(distinct CINID) as Customers
from #CalendarMonths c
JOIN #Spend s on s.Month = c.m1
WHERE EXISTS (
	SELECT 1 FROM #SpendC sc
	WHERE sc.CINID = s.CINID and sc.Month < c.m1 and sc.Month >= c.m12) 
and not exists (
	SELECT 1 FROM #Spend sc
	WHERE sc.CINID = s.CINID and sc.Month < c.m1 and sc.Month >= c.m12)
group by Month

UNION

select	Month
		, sum(Amount) as Sales
		, sum(Trans) as Trans
		, count(distinct CINID) as Customers
from #CalendarMonths c
JOIN #Spend s on s.Month = c.m12
WHERE EXISTS (
	SELECT 1 FROM #SpendC sc
	WHERE sc.CINID = s.CINID and sc.Month < c.m12 and sc.Month >= c.m24) 
and not exists (
	SELECT 1 FROM #Spend sc
	WHERE sc.CINID = s.CINID and sc.Month < c.m12 and sc.Month >= c.m24)
group by Month
) as #AcquireCS

	SELECT @msg = 'Create  #AcquireNew Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#AcquireNew') is not null drop table #AcquireNew
select	*
into #AcquireNew
from (
select	Month
		, sum(Amount) as Sales
		, sum(Trans) as Trans
		, count(distinct CINID) as Customers
from #CalendarMonths c
JOIN #Spend s on s.Month = c.m1
WHERE not EXISTS (
	SELECT 1 FROM #SpendC s2
	WHERE s2.CINID = s.CINID and s2.Month < c.m1 and s2.Month >= c.m12)
and not exists (
	SELECT 1 FROM #Spend sc
	WHERE sc.CINID = s.CINID and sc.Month < c.m1 and sc.Month >= c.m12)
Group by Month

UNION

select	Month
		, sum(Amount) as Sales
		, sum(Trans) as Trans
		, count(distinct CINID) as Customers
from #CalendarMonths c
JOIN #Spend s on s.Month = c.m12
WHERE not EXISTS (
	SELECT 1 FROM #SpendC s2
	WHERE s2.CINID = s.CINID and s2.Month < c.m12 and s2.Month >= c.m24)
and not exists (
	SELECT 1 FROM #Spend sc
	WHERE sc.CINID = s.CINID and sc.Month < c.m12 and sc.Month >= c.m24)
Group by Month
) as #AcquireNew

----------------------------------------------------------------------------------------
----------  Creating Relevant Metrics
----------------------------------------------------------------------------------------	


if object_id('tempdb..#TotalSpend') is not null drop table #TotalSpend
	select	c.m1
			,1.0*sum(Amount) as Sales
			,NULLIF(1.0*count(distinct CINID),0) as Customers
			,1.0*sum(Amount)/sum(Trans) as ATV
			,1.0*sum(Trans)/count(distinct CINID) as ATF

	into #TotalSpend
	from #MonthAll c
	left join #Spend s on c.m1 = Month
	group by c.m1
	order by c.m1 desc

if object_id('tempdb..#ExistingSpend') is not null drop table #ExistingSpend
	select	top 24 c.m1
			,1.0*sum(Sales) as Sales
			,1.0*sum(Customers) as Customers
			,1.0*sum(Sales)/sum(Trans) as ATV
			,1.0*sum(Trans)/sum(Customers) as ATF
	into #ExistingSpend
	from #MonthAll c
	left join #Existing e on c.m1 = Month
	group by c.m1
	order by c.m1 desc

if object_id('tempdb..#AcquireCSSpend') is not null drop table #AcquireCSSpend
	select	top 24 c.m1
			,1.0*sum(Sales) as Sales
			,1.0*sum(Customers) as Customers
			,1.0*sum(Sales)/sum(Trans) as ATV
			,1.0*sum(Trans)/sum(Customers) as ATF
	into #AcquireCSSpend
	from  #MonthAll c
	left join #AcquireCS a on c.m1 = Month
	group by c.m1
	order by c.m1 desc

select * from #acquireCS

if object_id('tempdb..#AcquireNewSpend') is not null drop table #AcquireNewSpend
	select	top 24 c.m1
			,1.0*sum(Sales) as Sales
			,1.0*sum(Customers) as Customers
			,1.0*sum(Sales)/sum(Trans) as ATV
			,1.0*sum(Trans)/sum(Customers) as ATF
	into #AcquireNewSpend
	from #MonthAll c
	left join #AcquireNew on c.m1 = Month
	group by c.m1
	order by c.m1 desc

if object_id('tempdb..#AggSpend') is not null drop table #AggSpend
select	top 24 c.m1 as Month
		,t.sales as Total_Sales
		,e.sales as Existing_Sales
		,cs.sales as AcquireCS_Sales
		,n.sales as AcquireNew_Sales

into #AggSpend
from  #MonthAll c
left join #ExistingSpend e on c.m1 = e.m1
left join #AcquireCSSpend cs on c.m1 = cs.m1
left join #AcquireNewSpend n on c.m1 = n.m1
left join #TotalSpend t on c.m1 = t.m1
order by c.m1 desc



----------------------------------------------------------------------------------------
----------  Identifying Spend Changes
----------------------------------------------------------------------------------------	


if object_id('tempdb..#TotalSpendChange') is not null drop table #TotalSpendChange
select	top 12 c.m1
		,1.0*Sales/LEAD(Sales, 12) OVER (ORDER BY t.m1 desc) as Sales_Change
		,1.0*Customers/LEAD(Customers, 12) OVER (ORDER BY t.m1 desc) as Customer_Change
		,1.0*ATV/LEAD(ATV, 12) OVER (ORDER BY t.m1 desc) as ATV_Change
		,1.0*ATF/LEAD(ATF, 12) OVER (ORDER BY t.m1 desc) as ATF_Change

into #TotalSpendChange
from #MonthAll c
left join #TotalSpend t on c.m1 = t.m1
order by 1 desc


if object_id('tempdb..#ExistingSpendChange') is not null drop table #ExistingSpendChange
select	top 12 c.m1
		,1.0*Sales/LEAD(Sales, 12) OVER (ORDER BY t.m1 desc) as Sales_Change
		,1.0*Customers/LEAD(Customers, 12) OVER (ORDER BY t.m1 desc) as Customer_Change
		,1.0*ATV/LEAD(ATV, 12) OVER (ORDER BY t.m1 desc) as ATV_Change
		,1.0*ATF/LEAD(ATF, 12) OVER (ORDER BY t.m1 desc) as ATF_Change

into #ExistingSpendChange
from #MonthAll c 
left join #ExistingSpend t on c.m1 = t.m1
order by 1 desc


if object_id('tempdb..#AcquireCSSpendChange') is not null drop table #AcquireCSSpendChange
select	top 12 c.m1
		,1.0*Sales/LEAD(Sales, 12) OVER (ORDER BY t.m1 desc) as Sales_Change
		,1.0*Customers/LEAD(Customers, 12) OVER (ORDER BY t.m1 desc) as Customer_Change
		,1.0*ATV/LEAD(ATV, 12) OVER (ORDER BY t.m1 desc) as ATV_Change
		,1.0*ATF/LEAD(ATF, 12) OVER (ORDER BY t.m1 desc) as ATF_Change

into #AcquireCSSpendChange
from #MonthAll c 
left join #AcquireCSSpend t on c.m1 = t.m1
order by 1 desc


if object_id('tempdb..#AcquireNewSpendChange') is not null drop table #AcquireNewSpendChange
select	top 12 c.m1
		,1.0*Sales/LEAD(Sales, 12) OVER (ORDER BY t.m1 desc) as Sales_Change
		,1.0*Customers/LEAD(Customers, 12) OVER (ORDER BY t.m1 desc) as Customer_Change
		,1.0*ATV/LEAD(ATV, 12) OVER (ORDER BY t.m1 desc) as ATV_Change
		,1.0*ATF/LEAD(ATF, 12) OVER (ORDER BY t.m1 desc) as ATF_Change

into #AcquireNewSpendChange
from #MonthAll c 
left join #AcquireNewSpend t on c.m1 = t.m1
order by 1 desc

----------------------------------------------------------------------------------------
----------  Output Tables
----------------------------------------------------------------------------------------

DECLARE @User nvarchar(30) = (SELECT USER_NAME())

exec ('
if object_id(''Sandbox.' + @User + '.DoC_TotalSpend'') is not null drop table Sandbox.' + @User + '.DoC_TotalSpend
if object_id(''Sandbox.' + @User + '.DoC_ExistingSpend'') is not null drop table Sandbox.' + @User + '.DoC_ExistingSpend
if object_id(''Sandbox.' + @User + '.DoC_AcquireCSSpend'') is not null drop table Sandbox.' + @User + '.DoC_AcquireCSSpend
if object_id(''Sandbox.' + @User + '.DoC_AcquireNewSpend'') is not null drop table Sandbox.' + @User + '.DoC_AcquireNewSpend
if object_id(''Sandbox.' + @User + '.DoC_AggSpend'') is not null drop table Sandbox.' + @User + '.DoC_AggSpend
if object_id(''Sandbox.' + @User + '.DoC_TotalSpendChange'') is not null drop table Sandbox.' + @User + '.DoC_TotalSpendChange
if object_id(''Sandbox.' + @User + '.DoC_ExistingSpendChange'') is not null drop table Sandbox.' + @User + '.DoC_ExistingSpendChange
if object_id(''Sandbox.' + @User + '.DoC_AcquireCSSpendChange'') is not null drop table Sandbox.' + @User + '.DoC_AcquireCSSpendChange
if object_id(''Sandbox.' + @User + '.DoC_AcquireNewSpendChange'') is not null drop table Sandbox.' + @User + '.DoC_AcquireNewSpendChange
if object_id(''Sandbox.' + @User + '.DoC_AcquireNewSpend'') is not null drop table Sandbox.' + @User + '.DoC_AcquireNewSpend
')

--select * From Sandbox.Shaun.DOC_TotalSpend order by m1

select 'All data tables generated replace existing tables in hidden sheet ''Data Sheet'''
select 'Copy table and replace Brand'
select BrandName FROM relational.brand where brandid=@Brand


select 'Copy table and replace Total Spend'

EXEC('
select	* 
into	Sandbox.' + @User + '.DoC_TotalSpend
from	#TotalSpend
')

select 'Copy table and replace Existing Spend'
EXEC('
select	*
into	Sandbox.' + @User + '.DoC_ExistingSpend
from	#ExistingSpend
')

select 'Copy table and replace Acquire: CS Spend'
EXEC('
select	*
into	Sandbox.' + @User + '.DoC_AcquireCSSpend
from	#AcquireCSSpend
')

select 'Copy table and replace Acquire: New Spend'
EXEC('
select	*
into	Sandbox.' + @User + '.DoC_AcquireNewSpend
from	#AcquireNewSpend
')

select 'Copy table and replace Agg Spend'
EXEC('
select	*
into	Sandbox.' + @User + '.DoC_AggSpend
from	#AggSpend
')

select 'Copy table and replace Total Spend Change'
EXEC('
select	*
into	Sandbox.' + @User + '.DoC_TotalSpendChange
from #TotalSpendChange
')

select 'Copy table and replace Existing Spend Change'
EXEC('
select	*
into	Sandbox.' + @User + '.DoC_ExistingSpendChange
from #ExistingSpendChange
')

select 'Copy table and replace Acquire: CS Spend Change'
EXEC('
select	*
into	Sandbox.' + @User + '.DoC_AcquireCSSpendChange
from #AcquireCSSpendChange
')

select 'Copy table and replace Acquire: New Spend Change'
EXEC('
select	*
into	Sandbox.' + @User + '.DoC_AcquireNewSpendChange
from #AcquireNewSpendChange
')

end
