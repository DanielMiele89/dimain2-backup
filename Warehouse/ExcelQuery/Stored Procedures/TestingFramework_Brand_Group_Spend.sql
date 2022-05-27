

/*=================================================================================================
Testing Framework - Brand Group Spend pull
Created 05/01/2017 by Shaun
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Brand_Group_Spend]	
	(@poptable varchar(max)
	,@brandname varchar(max)
	,@startdate varchar(10)
	,@enddate varchar(10))
AS
BEGIN
	SET NOCOUNT ON;

	EXEC('
		If object_id(''tempdb..#Population'') IS NOT NULL DROP TABLE #Population
		SELECT	* 
		INTO	#Population
		FROM ' + @poptable +  '

		-- Find the brand group
		Declare @brandgroupname varchar(max)
		Select @brandgroupname = BrandGroup from Sandbox.Shaun.Selected_BrandGroups_Final where BrandName = ''' + @brandname + '''
		
		Select		br.BrandID
					,cc.ConsumerCombinationID
		Into		#cc
		From		Sandbox.Shaun.Selected_BrandGroups_Final bg
		Inner Join  Warehouse.Relational.Brand br on br.BrandName = bg.BrandName
		Inner Join	Warehouse.Relational.ConsumerCombination cc on br.BrandID = cc.BrandID
		Where		bg.BrandGroup =  @brandgroupname

		CREATE CLUSTERED INDEX ix_BrandID on #cc(ConsumerCombinationID)

		Select		ct.CINID
					,sum(ct.Amount) as spend
		Into		#Spend
		From		Relational.ConsumerTransaction ct with (nolock)
		Inner Join	#Population p on p.ID=ct.cinid
		Inner Join	#cc cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
		Where		trandate between ''' + @startDate + ''' and ''' + @enddate + '''
		and			ct.IsRefund = 0
		Group By	ct.CINID

		select		distinct(p.id) as id
					,(case when s.spend is null then 
						0 
					else 
						s.spend 
					end) as brandgroupspend
		from		#Population p
		left join	#Spend s on s.CINID=p.ID
		order by	p.ID asc
		')

	-- Old Code (v1.0
	-- Retrieve the population table
	--EXEC('
	--	If object_ID(''Warehouse.ExcelQuery.TFPopulation'') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
	--	SELECT * 
	--	INTO Warehouse.ExcelQuery.TFPopulation
	--	FROM ' + @poptable +  '
	--	')

	-- -- Figure out the brand group
	--Declare @brandgroupname varchar(max)
	--select @brandgroupname = BrandGroup from Sandbox.Shaun.Selected_BrandGroups_Final where BrandName = @brandname
	
	--select		br.BrandID
	--			,cc.ConsumerCombinationID
	--into		#cc
	--from		Sandbox.Shaun.Selected_BrandGroups_Final bg
	--inner join  Warehouse.Relational.Brand br on br.BrandName = bg.BrandName
	--inner join	Warehouse.Relational.ConsumerCombination cc on br.BrandID = cc.BrandID
	--where		bg.BrandGroup = @brandgroupname

	--CREATE CLUSTERED INDEX ix_BrandID on #cc(ConsumerCombinationID)

	--select		ct.CINID
	--			,sum(Amount) as spend
	--into		#spend
	--from		Relational.ConsumerTransaction ct with (nolock)
	--			inner join ExcelQuery.TFPopulation p on p.ID=ct.cinid
	--			inner join #cc cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
	--where		trandate between @startDate and @enddate
	--and			ct.IsRefund = 0
	--group by	ct.CINID

	--select		distinct(p.id) as id
	--			,(case when s.spend is null then 0 else s.spend end) as brandgroupspend
	--from		ExcelQuery.TFPopulation p
	--left join	#spend s on s.CINID=p.ID
	--order by	p.ID asc

	--If object_ID('Warehouse.ExcelQuery.TFPopulation') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
end