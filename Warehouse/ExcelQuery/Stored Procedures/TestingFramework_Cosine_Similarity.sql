CREATE PROCEDURE [ExcelQuery].[TestingFramework_Cosine_Similarity]		
	(@poptable varchar(max)
	,@population varchar(max)
	,@brandname varchar(max)
	,@historical_startdate varchar(10)
	,@historical_enddate varchar(10)) --startDate
AS
BEGIN
SET NOCOUNT ON	

	IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
	CREATE TABLE #Population
		(
			id int
		)

	DECLARE @sql varchar(Max)
	SET @sql =	'SELECT	* FROM ' + @poptable +  ''

	INSERT INTO #Population execute (@sql)

if @population = 'nfi'
	begin
		-- Find the tracking club retailers.
		If Object_ID('tempdb..#trackingclub') IS NOT NULL DROP TABLE #trackingclub
		select distinct part.Name
		into			#trackingclub
		from			SLC_Report.dbo.Pan p
		inner join		SLC_Report.dbo.Match  m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
		inner join		SLC_Report.dbo.fan f on p.CompositeID = f.CompositeID
		inner join		SLC_Report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
		inner join		SLC_Report.dbo.Partner part on ro.PartnerID = part.ID
		inner join		Warehouse.MI.PartnerBrand pb on pb.PartnerID = part.id
		where			f.ClubID = 12 -- Quidco = 12
		--and				part.name != ''' + @brandname+ '''
		group by		part.Name
		order by		part.Name


		--- Set Club Id
		declare @clubid int
		set @clubid = 12 ---- 12 for Quidco, 143 for Easy Fundraising, 144 for Karrot and 145 for Next Jump and 146 for SMS


		-- Find spend at tracking club retailers
		If Object_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
			select          distinct p.CompositeID as id
			into			#Spenders
			from			slc_report.dbo.Pan p
			inner join		slc_report.dbo.Match m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
			inner join		slc_report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
			inner join		slc_report.dbo.Partner part on ro.PartnerID = part.ID
			inner join		slc_report.dbo.Trans t on t.MatchID = m.ID
			inner join		slc_report.dbo.TransactionType tt on tt.ID = t.TypeID
			inner join		#TrackingClub tc on tc.Name = part.Name
			where			m.status in (1)-- Valid transaction status
							and m.rewardstatus in (0,1)-- Valid customer status
							and cast(m.transactiondate as date) between @historical_startdate and @historical_enddate
							and m.Amount >= 0
							and part.name =  @brandname
			group by		p.CompositeID
			order by		p.CompositeID

		-- Find spend at tracking club retailers
		If Object_ID('tempdb..#templateSpend') IS NOT NULL DROP TABLE #templateSpend
			select          distinct p.CompositeID as id
							,part.Name
							,sum(m.Amount) as spend
			into			#templateSpend
			from			slc_report.dbo.Pan p
			inner join		slc_report.dbo.Match m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
			inner join		slc_report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
			inner join		slc_report.dbo.Partner part on ro.PartnerID = part.ID
			inner join		slc_report.dbo.Trans t on t.MatchID = m.ID
			inner join		slc_report.dbo.TransactionType tt on tt.ID = t.TypeID
			inner join		#Spenders s on s.id=p.CompositeID
			inner join		#TrackingClub tc on tc.Name = part.Name
			where			m.status in (1)-- Valid transaction status
							and m.rewardstatus in (0,1)-- Valid customer status
							and cast(m.transactiondate as date) between @historical_startdate and @historical_enddate 
							and m.Amount >= 0
			group by		p.CompositeID
							,part.Name
			order by		p.CompositeID
							,part.Name


		If Object_ID('tempdb..#templateCrossJoin') IS NOT NULL DROP TABLE #templateCrossJoin
			Select			s.ID
							,part.Name
			Into			#templateCrossJoin
			From			#Spenders s
			Cross Join		#trackingclub part


		If Object_ID('tempdb..#templateToPivot') IS NOT NULL DROP TABLE #templateToPivot
			Select			a.id
							,a.Name
							,b.spend
			Into			#templateToPivot
			From			#templateCrossJoin a
			Left Join		#templateSpend b on a.ID = b.ID and a.Name = b.Name

		-- Pivot spend at tracking club retailers
		If Object_ID('tempdb..#templateBrands') IS NOT NULL DROP TABLE #templateBrands
			Select distinct Name
			Into			#templateBrands
			From			#templateToPivot
		
		DECLARE @templateBrandList NVARCHAR(MAX) = STUFF(( SELECT ',' + QUOTENAME(Name) FROM #templatebrands where name != @brandname order by Name FOR XML PATH('')), 1, 1, '')
		SET @templateBrandList = replace(@templateBrandList, 'amp;', '')


		EXEC('	if object_id(''tempdb..templatePivot'') IS NOT NULL DROP TABLE templatePivot
				select  *, 1 as template
				into	#templatePivot
				from    #templateToPivot
				pivot	(
							sum(Spend) 
							FOR Name 
							in (' + @templateBrandList + ')
						) x
				order by ID		  
			
				Use Tempdb
				EXEC sp_rename	@objname = ''#templatePivot.[Caffè Nero]'',
								@newname = ''CaffeNero'',
								@objtype = ''COLUMN''
				'
			)
	end
if @population = 'my_rewards'
	begin

	--Declare @poptable varchar(max) = 'Sandbox.Shaun.amazon_loop'
	--Declare @population varchar(max) = 'my_rewards'
	--Declare @brandname varchar(max) = '485'
	--Declare @historical_startdate varchar(10) = '2015-01-01'
	--Declare @historical_enddate varchar(10) = '2015-12-31'
	--declare ''' + @population + ''' varchar(max)
	--declare ''' + @brandname+ ''' varchar(max)
	--declare ''' + @historical_startdate + ''' Date
	--declare ''' + @historical_enddate + ''' Date

	--set ''' + @population + ''' = 'my_rewards'
	--set ''' + @brandname+ ''' = 'Boux Avenue'
	--set ''' + @historical_startdate + ''' = '2016-01-01'
	--set ''' + @historical_enddate + ''' = '2016-01-25'


		if object_id('tempdb..#brandlistR') is not null drop table #brandlistR

		Select	*
		Into	#brandlistR 
		From	(
					Select	brandid
							,brandname
					From	Relational.Brand b
					Where	brandname = @brandname

					UNION
					
					Select	bl.brandid
							,bl.brandname
					From	ExcelQuery.alan_testing_framework_cosine_similarity_brandlist bl
					Join	Relational.Brand b on b.BrandID=bl.BrandID
				) x

		CREATE CLUSTERED INDEX ix_Brandid on #brandlistR(brandid)

		Declare @brandid int
		Set @brandid = (select brandid from #brandlistR where brandid = @brandname)

		if object_id('tempdb..#ccR') is not null drop table #ccR

		Select bl.brandname, bl.brandid, consumercombinationid
		Into #ccR
		From Relational.ConsumerCombination cc
		Join #brandlistR bl on bl.BrandID=cc.BrandID

		CREATE CLUSTERED INDEX ix_cc on #ccR(consumercombinationid)
		CREATE NONCLUSTERED INDEX ix_Brandid on #ccR(brandid)

		IF OBJECT_ID('tempdb..#customersR') IS NOT NULL DROP TABLE #customersR

		Select      distinct CL.CINID
		Into        #customersR
		From        warehouse.relational.customer c 
		Join        warehouse.Relational.CINList cl on c.SourceUID = cl.CIN
		Left Join   Staging.Customer_DuplicateSourceUID dup on dup.sourceUID = c.SourceUID 
		Where       dup.sourceuid  is NULL
		and         CurrentlyActive=1
		and         MarketableByEmail=1

		CREATE NONCLUSTERED INDEX ix_CINID on #customersR(CINID)


		if object_id('tempdb..#SpendersR') is not null drop table #SpendersR

		select		distinct top 50000 ct.CINID as id, newid() as newid
		into		#SpendersR
		from		Relational.ConsumerTransaction ct with (nolock)
		join		#ccR cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
		join		#customersR c on c.CINID=ct.CINID
		where		trandate between @historical_startdate and @historical_enddate
		and			@brandid = cc.brandid
		group by	ct.CINID
		order by newid()

		CREATE CLUSTERED INDEX ix_id on #SpendersR(id)

		if object_id('tempdb..#templateSpendR') is not null drop table #templateSpendR

		Select		distinct ct.CINID as id
					,cc.brandid
					,sum(amount) as spend
		Into		#templateSpendR
		From		Relational.ConsumerTransaction ct with (nolock)
		Join		#ccR cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
		Join		#SpendersR c on c.id=ct.CINID
		Where		trandate between @historical_startdate and @historical_enddate
		and			BrandID!= @brandid
		Group By	ct.CINID, brandid

		CREATE CLUSTERED INDEX ix_id on #templateSpendR(id)
		CREATE NONCLUSTERED INDEX ix_brandname on #templateSpendR(brandid)


		DECLARE @BrandList NVARCHAR(MAX) = STUFF(( SELECT ',' + QUOTENAME(brandid) FROM #brandlistR where BrandID!= @brandid FOR XML PATH('')), 1, 1, '')

		EXEC('
		if object_id(''ExcelQuery.alan_testing_framework_cosine_similarity_template_data'') is not null drop table ExcelQuery.alan_testing_framework_cosine_similarity_template_data

		Select		*, 1 as template
		Into		ExcelQuery.alan_testing_framework_cosine_similarity_template_data
		From		#templateSpendR
		Pivot (
					sum(spend) 
					FOR BrandID 
					in (' + @BrandList + ')
		) x
		')

		if object_id('tempdb..#acquireSpendR') is not null drop table #acquireSpendR

		Select		distinct c.id
					,cc.brandid
					,sum(amount) as spend
		Into		#acquireSpendR
		From		Relational.ConsumerTransaction ct with (nolock)
		Join		#ccR cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
		Join		#Population c on c.id=ct.CINID
		Where		trandate between @historical_startdate and @historical_enddate
		and			BrandID!= @brandid
		Group By	c.id
					,brandid

		CREATE CLUSTERED INDEX ix_id on #acquireSpendR(id)
		CREATE NONCLUSTERED INDEX ix_brandname on #acquireSpendR(brandid)

		if object_id('tempdb..#allacquireSpenderR') is not null drop table #allacquireSpenderR

		Select		distinct p.id
					,asr.brandid
					,spend
		Into		#allacquireSpenderR
		From		#Population p
		Left Join	#acquireSpendR asr on p.id=asr.id

		CREATE CLUSTERED INDEX ix_id on #allacquireSpenderR(id)
		CREATE NONCLUSTERED INDEX ix_brandname on #allacquireSpenderR(brandid)

		EXEC('
			If object_id(''ExcelQuery.alan_testing_framework_cosine_similarity_acquire_data'') is not null drop table ExcelQuery.alan_testing_framework_cosine_similarity_acquire_data
			Select		*
						,0 as template
			Into		ExcelQuery.alan_testing_framework_cosine_similarity_acquire_data
			From		#allacquireSpenderR
			Pivot (
						sum(spend) 
						FOR BrandID 
						in (' + @BrandList + ')
			) x
		')

		Select	*
		From	ExcelQuery.alan_testing_framework_cosine_similarity_template_data a
		UNION	ALL
		Select	*
		From	ExcelQuery.alan_testing_framework_cosine_similarity_acquire_data b
	end
end

--DECLARE @BrandList varchar(max)

--	EXEC('	If object_ID(''Warehouse.ExcelQuery.TFPopulation'') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
--		SELECT * 
--		INTO #Population
--		FROM ' + @poptable +  ' 

--if ''' + @population + ''' = ''nfi''
--	begin
--		-- Find the tracking club retailers.
--		If Object_ID(''tempdb..#trackingclub'') IS NOT NULL DROP TABLE #trackingclub
--		select distinct part.Name
--		into			#trackingclub
--		from			SLC_Report.dbo.Pan p
--		inner join		SLC_Report.dbo.Match  m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
--		inner join		SLC_Report.dbo.fan f on p.CompositeID = f.CompositeID
--		inner join		SLC_Report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
--		inner join		SLC_Report.dbo.Partner part on ro.PartnerID = part.ID
--		inner join		Warehouse.MI.PartnerBrand pb on pb.PartnerID = part.id
--		where			f.ClubID = 12 -- Quidco = 12
--		--and				part.name != ''' + @brandname+ '''
--		group by		part.Name
--		order by		part.Name


--		--- Set Club Id
--		declare @clubid int
--		set @clubid = 12 ---- 12 for Quidco, 143 for Easy Fundraising, 144 for Karrot and 145 for Next Jump and 146 for SMS


--		-- Find spend at tracking club retailers
--		If Object_ID(''tempdb..#Spenders'') IS NOT NULL DROP TABLE #Spenders
--			select          distinct p.CompositeID as id
--			into			#Spenders
--			from			slc_report.dbo.Pan p
--			inner join		slc_report.dbo.Match m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
--			inner join		slc_report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
--			inner join		slc_report.dbo.Partner part on ro.PartnerID = part.ID
--			inner join		slc_report.dbo.Trans t on t.MatchID = m.ID
--			inner join		slc_report.dbo.TransactionType tt on tt.ID = t.TypeID
--			inner join		#TrackingClub tc on tc.Name = part.Name
--			where			m.status in (1)-- Valid transaction status
--							and m.rewardstatus in (0,1)-- Valid customer status
--							and cast(m.transactiondate as date) between ''' + @historical_startdate + ''' and ''' + @historical_enddate + '''
--							and m.Amount >= 0
--							and part.name = ''' + @brandname+ '''
--			group by		p.CompositeID
--			order by		p.CompositeID

--		-- Find spend at tracking club retailers
--		If Object_ID(''tempdb..#templateSpend'') IS NOT NULL DROP TABLE #templateSpend
--			select          distinct p.CompositeID as id
--							,part.Name
--							,sum(m.Amount) as spend
--			into			#templateSpend
--			from			slc_report.dbo.Pan p
--			inner join		slc_report.dbo.Match m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
--			inner join		slc_report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
--			inner join		slc_report.dbo.Partner part on ro.PartnerID = part.ID
--			inner join		slc_report.dbo.Trans t on t.MatchID = m.ID
--			inner join		slc_report.dbo.TransactionType tt on tt.ID = t.TypeID
--			inner join		#Spenders s on s.id=p.CompositeID
--			inner join		#TrackingClub tc on tc.Name = part.Name
--			where			m.status in (1)-- Valid transaction status
--							and m.rewardstatus in (0,1)-- Valid customer status
--							and cast(m.transactiondate as date) between ''' + @historical_startdate + ''' and ''' + @historical_enddate + '''
--							and m.Amount >= 0
--			group by		p.CompositeID
--							,part.Name
--			order by		p.CompositeID
--							,part.Name


--		If Object_ID(''tempdb..#templateCrossJoin'') IS NOT NULL DROP TABLE #templateCrossJoin
--			Select			s.ID
--							,part.Name
--			Into			#templateCrossJoin
--			From			#Spenders s
--			Cross Join		#trackingclub part


--		If Object_ID(''tempdb..#templateToPivot'') IS NOT NULL DROP TABLE #templateToPivot
--			Select			a.id
--							,a.Name
--							,b.spend
--			Into			#templateToPivot
--			From			#templateCrossJoin a
--			Left Join		#templateSpend b on a.ID = b.ID and a.Name = b.Name

--		-- Pivot spend at tracking club retailers
--		If Object_ID(''tempdb..#templateBrands'') IS NOT NULL DROP TABLE #templateBrands
--			Select distinct Name
--			Into			#templateBrands
--			From			#templateToPivot

--		DECLARE @templateBrandList NVARCHAR(MAX) = STUFF(( SELECT '','' + QUOTENAME(Name) FROM #templatebrands where name != ''' + @brandname+ ''' order by Name FOR XML PATH('')), 1, 1, '')
--		SET @templateBrandList = replace(@templateBrandList, ''amp;'', '')


--		if object_id(''tempdb..templatePivot'') IS NOT NULL DROP TABLE templatePivot
--				select  *, 1 as template
--				into	#templatePivot
--				from    #templateToPivot
--				pivot	(
--							sum(Spend) 
--							FOR Name 
--							in (@templateBrandList)
--						) x
--				order by ID		  
			
--				Use Tempdb
--				EXEC sp_rename	@objname = ''#templatePivot.[Caffè Nero]'',
--								@newname = ''CaffeNero'',
--								@objtype = ''COLUMN''

--	end
--if ''' + @population + ''' = ''my_rewards''
--	begin


--		if object_id(''tempdb..#brandlistR'') is not null drop table #brandlistR

--		select *
--		into  #brandlistR from (
--		select brandid, brandname
--		from Relational.Brand b
--		where brandname = ''' + @brandname+ '''
--		UNION
--		select bl.brandid, brandname
--		from ExcelQuery.alan_testing_framework_cosine_similarity_brandlist bl
--		join Relational.Brand b on b.BrandID=bl.BrandID) as x

--		CREATE CLUSTERED INDEX ix_Brandid on #brandlistR(brandid)

--		declare @brandid int
--		set @brandid = (select brandid from #brandlistR where brandname = ''' + @brandname+ ''')

--		if object_id(''tempdb..#ccR'') is not null drop table #ccR

--		select bl.brandname, bl.brandid, consumercombinationid
--		into #ccR
--		from Relational.ConsumerCombination cc
--		join #brandlistR bl on bl.BrandID=cc.BrandID

--		CREATE CLUSTERED INDEX ix_cc on #ccR(consumercombinationid)
--		CREATE NONCLUSTERED INDEX ix_Brandid on #ccR(brandid)

--		IF OBJECT_ID(''tempdb..#customersR'') IS NOT NULL DROP TABLE #customersR

--		Select      distinct CL.CINID
--		into        #customersR
--		From        warehouse.relational.customer c 
--		join        warehouse.Relational.CINList cl on c.SourceUID = cl.CIN
--		left join   Staging.Customer_DuplicateSourceUID dup on dup.sourceUID = c.SourceUID 
--		where       dup.sourceuid  is NULL
--		and         CurrentlyActive=1
--		and         MarketableByEmail=1

--		CREATE NONCLUSTERED INDEX ix_CINID on #customersR(CINID)


--		if object_id(''tempdb..#SpendersR'') is not null drop table #SpendersR

--		select		distinct top 50000 ct.CINID as id, newid() as newid
--		into		#SpendersR
--		from		Relational.ConsumerTransaction ct with (nolock)
--		join		#ccR cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
--		join		#customersR c on c.CINID=ct.CINID
--		where		trandate between ''' + @historical_startdate + ''' and ''' + @historical_enddate + '''
--		and			@brandid = cc.brandid
--		group by	ct.CINID
--		order by newid()

--		CREATE CLUSTERED INDEX ix_id on #SpendersR(id)

--		if object_id(''tempdb..#templateSpendR'') is not null drop table #templateSpendR

--		select		distinct ct.CINID as id
--					,cc.brandid
--					,sum(amount) as spend
--		into		#templateSpendR
--		from		Relational.ConsumerTransaction ct with (nolock)
--		join		#ccR cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
--		join		#SpendersR c on c.id=ct.CINID
--		where		trandate between ''' + @historical_startdate + ''' and ''' + @historical_enddate + '''
--		and			BrandID!= @brandid
--		group by	ct.CINID, brandid

--		CREATE CLUSTERED INDEX ix_id on #templateSpendR(id)
--		CREATE NONCLUSTERED INDEX ix_brandname on #templateSpendR(brandid)


--		SET @BrandList = STUFF(( SELECT '','' + QUOTENAME(brandid) FROM #brandlistR where BrandID!= @brandid FOR XML PATH('''')), 1, 1, '''')


--		if object_id(''ExcelQuery.alan_testing_framework_cosine_similarity_template_data'') is not null drop table ExcelQuery.alan_testing_framework_cosine_similarity_template_data

--		select		*, 1 as template
--		into		ExcelQuery.alan_testing_framework_cosine_similarity_template_data
--		from		#templateSpendR
--		pivot (
--					sum(spend) 
--					FOR BrandID 
--					in (' + @BrandList + ')
--		) x


--		if object_id(''tempdb..#acquireSpendR'') is not null drop table #acquireSpendR

--		select		distinct c.id
--					,cc.brandid
--					,sum(amount) as spend
--		into		#acquireSpendR
--		from		Relational.ConsumerTransaction ct with (nolock)
--		join		#ccR cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
--		join		#population c on c.id=ct.CINID
--		where		trandate between ''' + @historical_startdate + ''' and ''' + @historical_enddate + '''
--		and			BrandID!= @brandid
--		group by	c.id, brandid

--		CREATE CLUSTERED INDEX ix_id on #acquireSpendR(id)
--		CREATE NONCLUSTERED INDEX ix_brandname on #acquireSpendR(brandid)

--		if object_id(''tempdb..#allacquireSpenderR'') is not null drop table #allacquireSpenderR

--		select		distinct p.id
--					,asr.brandid
--					,spend
--		into		#allacquireSpenderR
--		from		#population p
--		left join	#acquireSpendR asr on p.id=asr.id

--		CREATE CLUSTERED INDEX ix_id on #allacquireSpenderR(id)
--		CREATE NONCLUSTERED INDEX ix_brandname on #allacquireSpenderR(brandid)


--		if object_id(''ExcelQuery.alan_testing_framework_cosine_similarity_acquire_data'') is not null drop table ExcelQuery.alan_testing_framework_cosine_similarity_acquire_data
--		select		*, 0 as template
--		into		ExcelQuery.alan_testing_framework_cosine_similarity_acquire_data
--		from		#allacquireSpenderR
--		pivot (
--					sum(spend) 
--					FOR BrandID 
--					in (' + @BrandList + ')
--		) x

--		select *
--		from ExcelQuery.alan_testing_framework_cosine_similarity_template_data a
--		UNION ALL
--		select *
--		from ExcelQuery.alan_testing_framework_cosine_similarity_acquire_data b
--	end
--')
--end
