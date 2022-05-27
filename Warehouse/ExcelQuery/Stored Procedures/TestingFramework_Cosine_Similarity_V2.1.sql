CREATE PROCEDURE [ExcelQuery].[TestingFramework_Cosine_Similarity_V2.1]		
	(@poptable varchar(100)
	,@population varchar(50)
	,@brandid varchar(10)
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

	INSERT INTO #Population 
		EXECUTE (@sql)

IF @population = 'my_rewards'
	BEGIN
		-- Determine 100 Brand List + Brand of Interest
		if object_id('tempdb..#brandlistR') is not null drop table #brandlistR

		Select	*
		Into	#brandlistR 
		From	(
					Select	brandid
							,brandname
					From	Relational.Brand b
					Where	BrandID = @brandid

					UNION
					
					Select	bl.brandid
							,bl.brandname
					From	ExcelQuery.alan_testing_framework_cosine_similarity_brandlist bl
					Join	Relational.Brand b on b.BrandID=bl.BrandID
				) x


		CREATE CLUSTERED INDEX ix_Brandid on #brandlistR(brandid)

		-- Find ConsumerCombinationIDs
		if object_id('tempdb..#ccR') is not null drop table #ccR
		Select	bl.brandname
				,bl.brandid
				,consumercombinationid
		Into	#ccR
		From	Relational.ConsumerCombination cc
		Join	#brandlistR bl 
			on bl.BrandID=cc.BrandID

		CREATE CLUSTERED INDEX ix_cc on #ccR(consumercombinationid)
		CREATE NONCLUSTERED INDEX ix_Brandid on #ccR(brandid)

		-- Find a random customer group
		IF OBJECT_ID('tempdb..#customersR') IS NOT NULL DROP TABLE #customersR
		
		Select      distinct CL.CINID
		Into        #customersR
		From        warehouse.relational.customer c 
		Join        warehouse.Relational.CINList cl on c.SourceUID = cl.CIN
		Left Join   Staging.Customer_DuplicateSourceUID dup on dup.sourceUID = c.SourceUID 
		Where       dup.sourceuid  is NULL
				and	CurrentlyActive=1
				and	MarketableByEmail=1

		CREATE NONCLUSTERED INDEX ix_CINID on #customersR(CINID)

		-- Find up to 50,000 spenders (@ the brand in question) from this group
		if object_id('tempdb..#SpendersR') is not null drop table #SpendersR

		Select		distinct top 50000 ct.CINID as id
					,newid() as newid
		Into		#SpendersR
		From		Relational.ConsumerTransaction ct with (nolock)
		Join		#ccR cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
		Join		#customersR c on c.CINID=ct.CINID
		Where		trandate between @historical_startdate and @historical_enddate
				and	@brandid = cc.brandid
		Group by	ct.CINID
		Order by	newid()

		CREATE CLUSTERED INDEX ix_id on #SpendersR(id)

		-- Find the spend profile (across 100 brands) for the Spenders
		if object_id('tempdb..#templateSpendR') is not null drop table #templateSpendR

		Select		distinct ct.CINID as id
					,cc.brandid
					,sum(amount) as spend
		Into		#templateSpendR
		From		Relational.ConsumerTransaction ct with (nolock)
		Join		#ccR cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
		Join		#SpendersR c on c.id=ct.CINID
		Where		trandate between @historical_startdate and @historical_enddate
			and		BrandID!= @brandid
		Group By	ct.CINID, brandid

		CREATE CLUSTERED INDEX ix_id on #templateSpendR(id)
		CREATE NONCLUSTERED INDEX ix_brandname on #templateSpendR(brandid)

		-- Pivot these spenders data (Long Data => Wide Data)
		DECLARE @BrandList NVARCHAR(MAX) = STUFF(( SELECT ',' + QUOTENAME(brandid) FROM #brandlistR where BrandID!= @brandid FOR XML PATH('')), 1, 1, '')

		EXEC('
				if object_id(''ExcelQuery.alan_testing_framework_cosine_similarity_template_data'') is not null drop table ExcelQuery.alan_testing_framework_cosine_similarity_template_data

				Select		*
							,1 as template
				Into		ExcelQuery.alan_testing_framework_cosine_similarity_template_data
				From		#templateSpendR
				Pivot		(
								sum(spend) 
								FOR BrandID 
								in (' + @BrandList + ')
							) x
			')

		-- Find the Spend Profiles (at the 100) brands for the population group
		if object_id('tempdb..#acquireSpendR') is not null drop table #acquireSpendR

		Select		distinct c.id
					,cc.brandid
					,sum(amount) as spend
		Into		#acquireSpendR
		From		Relational.ConsumerTransaction ct with (nolock)
		Join		#ccR cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
		Join		#Population c on c.id=ct.CINID
		Where		trandate between @historical_startdate and @historical_enddate
				and	BrandID!= @brandid
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

		-- Pivot Shopper Group data (100 + 1) From Long => Wide

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

		-- Return the union of the two 
		Select	*
		From	ExcelQuery.alan_testing_framework_cosine_similarity_template_data a
		UNION	ALL		
		Select	*
		From	ExcelQuery.alan_testing_framework_cosine_similarity_acquire_data b

	END
--if @population = 'nfi'
	--begin
	--	-- Find the tracking club retailers.
	--	If Object_ID('tempdb..#trackingclub') IS NOT NULL DROP TABLE #trackingclub
	--	select distinct part.Name
	--	into			#trackingclub
	--	from			SLC_Report.dbo.Pan p
	--	inner join		SLC_Report.dbo.Match  m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
	--	inner join		SLC_Report.dbo.fan f on p.CompositeID = f.CompositeID
	--	inner join		SLC_Report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
	--	inner join		SLC_Report.dbo.Partner part on ro.PartnerID = part.ID
	--	inner join		Warehouse.MI.PartnerBrand pb on pb.PartnerID = part.id
	--	where			f.ClubID = 12 -- Quidco = 12
	--	--and				part.name != ''' + @brandname+ '''
	--	group by		part.Name
	--	order by		part.Name


	--	--- Set Club Id
	--	declare @clubid int
	--	set @clubid = 12 ---- 12 for Quidco, 143 for Easy Fundraising, 144 for Karrot and 145 for Next Jump and 146 for SMS


	--	-- Find spend at tracking club retailers
	--	If Object_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
	--		select          distinct p.CompositeID as id
	--		into			#Spenders
	--		from			slc_report.dbo.Pan p
	--		inner join		slc_report.dbo.Match m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
	--		inner join		slc_report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
	--		inner join		slc_report.dbo.Partner part on ro.PartnerID = part.ID
	--		inner join		slc_report.dbo.Trans t on t.MatchID = m.ID
	--		inner join		slc_report.dbo.TransactionType tt on tt.ID = t.TypeID
	--		inner join		#TrackingClub tc on tc.Name = part.Name
	--		where			m.status in (1)-- Valid transaction status
	--						and m.rewardstatus in (0,1)-- Valid customer status
	--						and cast(m.transactiondate as date) between @historical_startdate and @historical_enddate
	--						and m.Amount >= 0
	--						and part.name =  @brandid
	--		group by		p.CompositeID
	--		order by		p.CompositeID

	--	-- Find spend at tracking club retailers
	--	If Object_ID('tempdb..#templateSpend') IS NOT NULL DROP TABLE #templateSpend
	--		select          distinct p.CompositeID as id
	--						,part.Name
	--						,sum(m.Amount) as spend
	--		into			#templateSpend
	--		from			slc_report.dbo.Pan p
	--		inner join		slc_report.dbo.Match m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
	--		inner join		slc_report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
	--		inner join		slc_report.dbo.Partner part on ro.PartnerID = part.ID
	--		inner join		slc_report.dbo.Trans t on t.MatchID = m.ID
	--		inner join		slc_report.dbo.TransactionType tt on tt.ID = t.TypeID
	--		inner join		#Spenders s on s.id=p.CompositeID
	--		inner join		#TrackingClub tc on tc.Name = part.Name
	--		where			m.status in (1)-- Valid transaction status
	--						and m.rewardstatus in (0,1)-- Valid customer status
	--						and cast(m.transactiondate as date) between @historical_startdate and @historical_enddate 
	--						and m.Amount >= 0
	--		group by		p.CompositeID
	--						,part.Name
	--		order by		p.CompositeID
	--						,part.Name


	--	If Object_ID('tempdb..#templateCrossJoin') IS NOT NULL DROP TABLE #templateCrossJoin
	--		Select			s.ID
	--						,part.Name
	--		Into			#templateCrossJoin
	--		From			#Spenders s
	--		Cross Join		#trackingclub part


	--	If Object_ID('tempdb..#templateToPivot') IS NOT NULL DROP TABLE #templateToPivot
	--		Select			a.id
	--						,a.Name
	--						,b.spend
	--		Into			#templateToPivot
	--		From			#templateCrossJoin a
	--		Left Join		#templateSpend b on a.ID = b.ID and a.Name = b.Name

	--	-- Pivot spend at tracking club retailers
	--	If Object_ID('tempdb..#templateBrands') IS NOT NULL DROP TABLE #templateBrands
	--		Select distinct a.id
	--		Into			#templateBrands
	--		From			#templateToPivot
		
	--	DECLARE @templateBrandList NVARCHAR(MAX) = STUFF(( SELECT ',' + QUOTENAME(id) FROM #templatebrands where id != @brandid order by id FOR XML PATH('')), 1, 1, '')
	--	SET @templateBrandList = replace(@templateBrandList, 'amp;', '')


	--	EXEC('	if object_id(''tempdb..templatePivot'') IS NOT NULL DROP TABLE templatePivot
	--			select  *, 1 as template
	--			into	#templatePivot
	--			from    #templateToPivot
	--			pivot	(
	--						sum(Spend) 
	--						FOR id 
	--						in (' + @templateBrandList + ')
	--					) x
	--			order by ID		  
	--			'
	--		)
	--end
END