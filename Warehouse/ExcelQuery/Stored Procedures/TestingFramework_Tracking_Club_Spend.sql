CREATE PROCEDURE [ExcelQuery].[TestingFramework_Tracking_Club_Spend]	

	(@poptable varchar(max)
	,@tracking_club_spend int
	,@historical_startdate varchar(10)
	,@historical_enddate varchar(10))	--startDate

AS
BEGIN
	SET NOCOUNT ON

	--Declare @poptable varchar(max) = 'Sandbox.Shaun.BP_Loop'
	--		,@tracking_club_spend int = 1
	--		,@historical_startdate varchar(10) = '2015-01-01'
	--		,@historical_enddate varchar(10) = '2015-01-02'

	EXEC('
	SELECT	* 
	INTO	#Population
	FROM ' + @poptable +  '

	if ' + @tracking_club_spend + ' = 1
		begin

			IF OBJECT_ID(''tempdb..#BrandList'') IS NOT NULL DROP TABLE #BrandList
			Select	BrandID
					,BrandName
			Into	#BrandList
			From	Relational.Brand
			Where	BrandID in (190,156,736,741,738,116,123,737,482,25,106,251,142,188,12,29,483,1111,1084,1374,19,294,417,1083,1079,58,310,83,1696,16,452,104,227,1202,1174,1341,195,75,528,869,1162,1887,1170,23,1001,370,253,509,107,170,1363,1365,1480,207,487,7,283,391,454,1904,193,475,305,6,68,78,1122,1367,1703,149,438,125,1146,1360,46,246,1507,119,249,1757,869,1010,361,1370)

			IF OBJECT_ID(''tempdb..#occ'') IS NOT NULL DROP TABLE #Occ 
			Select		b.BrandID
						,cc.consumercombinationid
			Into		#cc
			From		Relational.ConsumerCombination cc
			Join		#brandlist b on b.brandID=cc.brandID

			CREATE CLUSTERED INDEX ix_BID on #cc(BrandID)
			CREATE NONCLUSTERED INDEX ix_BCID on #cc(consumercombinationid)

			if object_id(''tempdb..#spend'') is not null drop table #spend

			Select		p.CINID
						,cc.BrandID
						,Sum(Amount) as Amount
			Into		#spend
			From		Relational.ConsumerTransaction ct with (nolock)
			Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			Join		#Population p on p.ID=ct.CINID
			Where		trandate between ''' + @historical_startdate + ''' and ''' + @historical_enddate + '''
			Group By	ct.CINID, cc.BrandID
		end
	else
		begin
			Select		p.ID
						,null
			From		#Population p
			Order By	ID asc
		end
	')




	If object_ID('Warehouse.ExcelQuery.TFPopulation') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation

	-- Old
	--EXEC('	If object_ID(''Warehouse.ExcelQuery.TFPopulation'') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
	--SELECT * 
	--INTO Warehouse.ExcelQuery.TFPopulation
	--FROM ' + @poptable +  '')

	--if @tracking_club_spend = 1
	--	begin

	--		IF OBJECT_ID('tempdb..#brandlist') IS NOT NULL DROP TABLE #brandlist

	--		select brandid, BrandName
	--		into #brandlist
	--		from Relational.Brand
	--		where brandid in (190,156,736,741,738,116,123,737,482,25,106,251,142,188,12,29,483,1111,1084,1374,19,294,417,1083,1079,58,310,83,1696,16,452,104,227,1202,1174,1341,195,75,528,869,1162,1887,1170,23,1001,370,253,509,107,170,1363,1365,1480,207,487,7,283,391,454,1904,193,475,305,6,68,78,1122,1367,1703,149,438,125,1146,1360,46,246,1507,119,249,1757,869,1010,361,1370)

	--		if object_id('tempdb..#occ') is not null drop table #occ

	--		select		b.BrandID, consumercombinationid
	--		into		#occ
	--		from		Relational.ConsumerCombination cc
	--		join		#brandlist b on b.brandID=cc.brandID

	--		CREATE CLUSTERED INDEX ix_BID on #occ(BrandID)
	--		CREATE NONCLUSTERED INDEX ix_BCID on #occ(consumercombinationid)

	--		if object_id('tempdb..#spend') is not null drop table #spend

	--		select		ct.CINID
	--					,cc.BrandID
	--					,Sum(Amount) as Amount
	--		into		#spend
	--		from		Relational.ConsumerTransaction ct with (nolock)
	--		join		#occ cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
	--		join		ExcelQuery.TFPopulation p on p.ID=ct.CINID
	--		where		trandate between @historical_startdate and @historical_enddate
	--		group by	ct.CINID, cc.BrandID
	--	end
	--else
	--	begin
	--		select	p.ID
	--				,null
	--		from ExcelQuery.TFPopulation p
	--		order by	ID asc
	--	end

	--If object_ID('Warehouse.ExcelQuery.TFPopulation') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation

end
