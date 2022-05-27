

/*=================================================================================================
Sales DRIVERS TO CHANGE
Version 1: A. Devereux 25/04/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 40 Minutes W/ Fixed Base; 20 Minutes W/O Fixed Base

CREATE PROCEDURE [Prototype].[Drivers_to_Change_v2]		
	(@Edate Date		--end date
	,@Brand int			--brand
	--,@FBRequired int	--fixed base required (#TODO change to WETS fixed base)
	,@Reward int		--my rewards only
	,@onlineVariable bit)		--(All transactions:NULL, Online only:1, offline only:0)
AS
BEGIN
	SET NOCOUNT ON;

	----------------------------------------------------------------------------------------
	----------  Setting Parameters
	----------------------------------------------------------------------------------------


	Declare		@Today			datetime,
				@time			DATETIME,
				@msg			VARCHAR(2048)
	Set			@Today			= getdate()


	--Declare		@Edate DATE = '2017-04-30'	-- End Date of the data you want to look at
	--Declare		@Brand INT = 1360			-- BrandID of brand you are interested in
	--Declare		@FBRequired	INT = 0			-- 1 = Yes, 0 = No
	--Declare		@Reward	INT	= 0				-- 0 = Full Fixed Base (incl. MyRewards), 1 = MyRewards ONLY, 2 = Fixed Base excl. MyRewards 
	--Declare		@onlineVariable	INT = NULL  -- 1 = Online Only, 0 = Offline Only, NULL = None

	----------------------------------------------------------------------------------------
	----------  CREATING APPROPRIATE DATE RANGES
	----------------------------------------------------------------------------------------

	SELECT		@msg	= 'Create #Dates Table'
	EXEC		warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	CREATE TABLE #Dates	
		(
			Dates DATE NULL		 
		)

	Declare @EdateMonthStart DATE = DATEADD(m, DATEDIFF(m, 0, @Edate), 0)
	Declare	@SDate	DATE = DATEADD(month,-37,@EdateMonthStart)
	
	INSERT INTO	#Dates VALUES	
		(@EdateMonthStart)
		,(@SDate)

	-- Select * From #dates
	
	SELECT @msg = 'Create #CalendarMonths Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

	IF OBJECT_ID('tempdb..#Monthall') IS NOT NULL DROP TABLE #Monthall					
	;with MonthAll
	as (
			Select @SDate as startdate
			UNION ALL
			Select DATEADD(m, 1, startdate)
			from MonthAll
			where startdate < DATEADD(m,-1,@Edate)
		)
	Select startdate as m1
	Into	#Monthall
	From	monthall
						
	-- Select * From #monthall

	IF OBJECT_ID('tempdb..#CalendarMonths') IS NOT NULL DROP TABLE #CalendarMonths						
	CREATE TABLE #CalendarMonths 
		(
			Rownum int
			,m1 DATE
			,m12 DATE
			,m24 DATE
			,PRIMARY KEY (m1)
		)


	SELECT @msg = 'Populate #CalendarMonths Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

	DECLARE	@basedate	DATE = (select dateadd(month,-11,@EdateMonthStart))
			,@offset	INT  = 0

	WHILE (@offset < 12)
		BEGIN
				INSERT INTO #CalendarMonths VALUES 
					(
						@offset,
						dateadd(month,@offset,@basedate),
						dateadd(month,@offset-12,@basedate),
						dateadd(month,@offset-24,@basedate)
					)

			SET @offset = @offset + 1
		END

	-- Select * From #calendarmonths

	----------------------------------------------------------------------------------------
	----------  Selecting Partner and Competitor With Consumer Combinations
	----------------------------------------------------------------------------------------	
	SELECT @msg = 'Create  #PartnerList Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

	IF OBJECT_ID('tempdb..#PartnerList') IS NOT NULL DROP TABLE #PartnerList
	Create Table #PartnerList
					(
						BrandID Int
					)

	Insert Into #PartnerList Values 
		(@Brand)

	SELECT @msg = 'Create  #competitorlist Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

	IF OBJECT_ID('tempdb..#competitorlist') IS NOT NULL DROP TABLE #competitorlist
	Select		competitorID	as BrandID
	Into		#competitorlist
	From		relational.BrandCompetitor bc
	Join		#PartnerList p	on bc.BrandID = p.BrandID

	CREATE NONCLUSTERED INDEX ix_BrandID on #competitorlist(BrandID)

	SELECT @msg = 'Create  #cc_partner Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

	IF OBJECT_ID('tempdb..#cc_partner') IS NOT NULL DROP TABLE #cc_partner
	Select	b.brandid
			,ConsumerCombinationID
	Into	#cc_partner
	From	#PartnerList b
	Join	Relational.ConsumerCombination bm on b.brandid=bm.BrandID

	CREATE CLUSTERED INDEX ix_brandID on #cc_partner(BrandID)
	CREATE NONCLUSTERED INDEX ix_ccID on #cc_partner(ConsumerCombinationID)

	SELECT @msg = 'Create  #cc_competitor Table'
	EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

	IF OBJECT_ID('tempdb..#cc_competitor') IS NOT NULL DROP TABLE #cc_competitor
	Select	c.brandid
			,ConsumerCombinationID
	Into	#cc_competitor
	From	#competitorlist c
	Join	Relational.ConsumerCombination bm on c.brandid=bm.BrandID

	CREATE CLUSTERED INDEX ix_brandID on #cc_competitor(BrandID)
	CREATE NONCLUSTERED INDEX ix_ccID on #cc_competitor(ConsumerCombinationID)

	----------------------------------------------------------------------------------------
	----------  Creating the fixed base
	----------------------------------------------------------------------------------------

	--IF @FBRequired = 1
	--	BEGIN
	--		Declare @fixedbasestartdate DATE = (select top 1 dates from #Dates order by dates asc)
	--		Declare @fixedbaseenddate DATE = @edate

	--		-- Select @fixedbasestartdate, @fixedbaseenddate

	--		IF OBJECT_ID('Warehouse.InsightArchive.alanDtC_fixedbase') IS NOT NULL DROP TABLE Warehouse.InsightArchive.alanDtC_fixedbase
	--		EXEC Relational.CustomerBase_Generate 'alanDtC_fixedbase', @fixedbasestartdate, @fixedbaseenddate
	--	END

	----------------------------------------------------------------------------------------
	----------  Creating Customer List
	----------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#customerlist') IS NOT NULL DROP TABLE #customerlist
	CREATE TABLE #customerlist
				(
					CINID INT
					,RowNo INT Identity
				)

	IF @Reward = 0 -- Full Fixed Base (incl. MyRewards Customers)
		BEGIN					
			INSERT INTO #CustomerList
				SELECT		CINID
				FROM		Warehouse.InsightArchive.SalesVisSuite_FixedBase

		END
	IF @Reward = 1 -- MyRewards ONLY	
		BEGIN
			INSERT INTO #CustomerList
				Select	fb.CINID
				From	Warehouse.InsightArchive.SalesVisSuite_FixedBase fb
				Join	Warehouse.Relational.CINList cl on fb.CINID = cl.CINID -- to get CINID
				Join	Warehouse.Relational.Customer c on c.SourceUID = cl.CIN ---to get sourceuid			

		END
	IF @Reward = 2 -- Full Fixed Base (excl. MyRewards Customers)
		BEGIN
			INSERT INTO #CustomerList
				Select	fb.CINID
				From	Warehouse.InsightArchive.SalesVisSuite_FixedBase fb
				Left Outer Join	(
									Select	distinct CINID
									From	Warehouse.Relational.Customer c
									Join	Warehouse.Relational.CINLIST cl on c.SourceUID = cl.CIN
								) c
					On	fb.CINID = c.CINID
				Where	c.CINID IS NULL
		END

	CREATE CLUSTERED INDEX ix_CINID ON #CustomerList(CINID)

	----------------------------------------------------------------------------------------
	----------  Extracting Partner Spend
	----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Spend') IS NOT NULL DROP TABLE #Spend
	CREATE TABLE #Spend
		(
			CINID		int
			,Amount		int
			,Trans		int
			,Month		date
		)

	DECLARE	@StartDate	DATE = (SELECT Top 1 * FROM #Dates Order by dates asc)
	Print @StartDate

	Declare	@RowNo int = 1
			,@MaxRowNo int = (Select Max(RowNo) From #CustomerList)
			,@Chunksize int = 100000


	While @RowNo <= @MaxRowNo
		Begin
					SELECT @msg = 'Populate Spend table - '+Cast(@RowNo as varchar)
					EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT
			
					INSERT INTO #Spend
						Select		ct.CINID
									,sum(Amount) as Amount
									,count(1) as Trans
									,DATEADD(m, DATEDIFF(m, 0, ct.TranDate), 0)

						From		Relational.ConsumerTransaction ct with (nolock)
						Join		#CustomerList c on c.cinid=ct.cinid
						Join		#cc_partner b on b.ConsumerCombinationID=ct.ConsumerCombinationID

						Where		ISRefund = 0 
									and c.RowNo Between @RowNo and @RowNo+(@ChunkSize-1) 
									and	(isonline = @onlineVariable or @onlineVariable IS NULL)
									and (ct.TranDate between @StartDate and @Edate)

						Group by	ct.CINID
									,b.BrandID
									,DATEADD(m, DATEDIFF(m, 0, ct.TranDate), 0)

			Set @RowNo = @RowNo+@Chunksize
		End

	CREATE NONCLUSTERED INDEX ix_Month on #Spend(Month)
	CREATE NONCLUSTERED INDEX ix_CINID on #Spend(CINID)


	-- Below remains to be Alan's code
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

	Select top 10 * From #Spend

	If Object_ID('tempdb..#Existing') IS NOT NULL DROP TABLE #Existing
	Select	*
	Into	#Existing
	From	(
				Select	Month
						,sum(Amount) as Sales
						,sum(Trans) as Trans
						,count(distinct CINID) as Customers
				From #CalendarMonths c
				Join #Spend s on s.Month = c.m1
				Where EXISTS (
								Select	1 
								From	#Spend s2
								Where	s2.CINID = s.CINID
									and c.m12 <= s2.Month	
									and	s2.Month < c.m1 
							 )
				Group by Month

				UNION

				Select	Month
						,sum(Amount) as Sales
						,sum(Trans) as Trans
						,count(distinct CINID) as Customers
				From	#CalendarMonths c
				Join	#Spend s on s.Month = c.m12
				Where EXISTS (
								Select	1 
								From	#Spend s2
								Where	s2.CINID = s.CINID 
									and c.m24 <= s2.Month
									and s2.Month < c.m12 
				)
				Group by Month
			) as #Existing



		SELECT @msg = 'Create  #AcquireCS Table'
		EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

	If Object_ID('tempdb..#AcquireCS') IS NOT NULL DROP TABLE #AcquireCS
	Select	*
	Into	#AcquireCS
	From	(
				Select	Month
						,sum(Amount) as Sales
						,sum(Trans) as Trans
						,count(distinct CINID) as Customers
				From	#CalendarMonths c
				Join	#Spend s on s.Month = c.m1
				Where	EXISTS (
								Select	1 
								From	#SpendC sc
								Where	sc.CINID = s.CINID
									and	c.m12 <= sc.Month
									and sc.Month < c.m1 
								) 
				and		NOT EXISTS (
								Select	1 
								From	#Spend sc
								Where	sc.CINID = s.CINID
									and c.m12 <= sc.Month 
									and sc.Month < c.m1 
								)
				Group by Month

				UNION

				Select	Month
						,sum(Amount) as Sales
						,sum(Trans) as Trans
						,count(distinct CINID) as Customers
				From	#CalendarMonths c
				Join	#Spend s on s.Month = c.m12
				Where	EXISTS (
								Select	1 
								From	#SpendC sc
								Where	sc.CINID = s.CINID
									and c.m24 <= sc.Month 
									and sc.Month < c.m12 
								) 
				and		NOT EXISTS (
								Select	1 
								From	#Spend sc
								Where	sc.CINID = s.CINID 
									and c.m24 <= sc.Month
									and sc.Month < c.m12 
								)
				Group by Month
			) as #AcquireCS


		SELECT @msg = 'Create  #AcquireNew Table'
		EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

	If Object_ID('tempdb..#AcquireNew') IS NOT NULL DROP TABLE #AcquireNew
	Select	*
	Into	#AcquireNew
	From	(
				Select	Month
						,sum(Amount) as Sales
						,sum(Trans) as Trans
						,count(distinct CINID) as Customers
				From	#CalendarMonths c
				Join	#Spend s on s.Month = c.m1
				Where	NOT EXISTS (
									Select	1 
									From	#SpendC s2
									Where	s2.CINID = s.CINID
										and c.m12 <= s2.Month 
										and s2.Month < c.m1 
								   )
				and		NOT EXISTS (
									Select	1 
									From	#Spend sc
									Where	sc.CINID = s.CINID
										and c.m12 <= sc.Month
										and sc.Month < c.m1 
									)
				Group by Month

				UNION

				Select	Month
						,sum(Amount) as Sales
						,sum(Trans) as Trans
						,count(distinct CINID) as Customers
				From	#CalendarMonths c
				Join	#Spend s on s.Month = c.m12
				WHERE	NOT EXISTS (
									Select	1 
									From	#SpendC s2
									Where	s2.CINID = s.CINID
										and c.m24 <= s2.Month
										and s2.Month < c.m12 
									)
				and		NOT EXISTS (
									Select	1 
									From	#Spend sc
									Where	sc.CINID = s.CINID 
									and		c.m24 <= sc.Month
									and		sc.Month < c.m12 
									)
				Group by Month
			) as #AcquireNew

	----------------------------------------------------------------------------------------
	----------  Creating Relevant Metrics
	----------------------------------------------------------------------------------------	


	If Object_ID('tempdb..#TotalSpend') IS NOT NULL DROP TABLE #TotalSpend
	Select		c.m1
				,1.0*sum(Amount) as Sales
				,NULLIF(1.0*count(distinct CINID),0) as Customers
				,1.0*sum(Amount)/sum(Trans) as ATV
				,1.0*sum(Trans)/count(distinct CINID) as ATF
	Into		#TotalSpend
	From		#MonthAll c
	Left Join	#Spend s on c.m1 = Month
	Group by	c.m1
	Order by	c.m1 desc

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

	EXEC ('
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
			Select	* 
			Into	Sandbox.' + @User + '.DoC_TotalSpend
			From	#TotalSpend
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
