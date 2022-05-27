

/*=================================================================================================
Sales Visualisation Refresh
Version 1: A. Devereux 25/02/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 1 Hour

create PROCEDURE [ExcelQuery].[TestingFramework_Total_Spend_recency]	
	(@poptable varchar(max)
	,@startdate varchar(10)
	,@enddate varchar(10))
AS
BEGIN
	SET NOCOUNT ON;

	EXEC('
		SELECT	* 
		INTO	#Population
		FROM ' + @poptable +  '

		Select		b.brandid
					,ConsumerCombinationID
		Into		#cc
		From		Relational.ConsumerCombination cc
		Inner Join	Relational.Brand b on b.brandid = cc.brandid

		CREATE CLUSTERED INDEX ix_CCID on #cc(ConsumerCombinationID)
		CREATE INDEX ix_BrandID on #cc(BrandID)

		Select		ct.CINID
					,datediff(day,max(trandate),@enddate) as spend_recency
		Into		#spend_recency
		From		Relational.ConsumerTransaction ct with (nolock)
		Inner Join	#Population p on p.ID=ct.cinid
		Inner Join	#cc cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
		Where		trandate between ''' + @startDate + ''' and ''' + @enddate + '''
		and			ct.IsRefund = 0
		Group By	ct.CINID

		Select		distinct p.id as id
					,(case when s.spend_recency is null then
						365
					else
						s.spend_recency
					end) as spend_recency
		From		#Population p
		Left Join	#spend_recency s on s.CINID=p.ID
		Order By	p.ID asc
		')

	---- Old Code
	--EXEC('
	--	If object_ID(''Warehouse.ExcelQuery.TFPopulation'') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
	--	SELECT * 
	--	INTO Warehouse.ExcelQuery.TFPopulation
	--	FROM ' + @poptable +  '
	--	')

	--select		b.brandid
	--			,ConsumerCombinationID
	--into		#cc
	--from		Relational.ConsumerCombination cc
	--inner join	relational.brand b on b.brandid = cc.brandid

	--CREATE CLUSTERED INDEX ix_CCID on #cc(ConsumerCombinationID)
	--CREATE INDEX ix_BrandID on #cc(BrandID)

	--select		ct.CINID
	--			,sum(Amount) as spend
	--into		#spend
	--from		Relational.ConsumerTransaction ct with (nolock)
	--			inner join ExcelQuery.TFPopulation p on p.ID=ct.cinid
	--			inner join #cc cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
	--where		trandate between @startDate and @enddate
	--and			ct.IsRefund = 0
	--group by	ct.CINID

	--select		distinct p.id as id
	--			,(case when s.spend is null then 0 else s.spend end) as spend
	--from		ExcelQuery.TFPopulation p
	--left join	#spend s on s.CINID=p.ID
	--order by	p.ID asc

	--If object_ID('Warehouse.ExcelQuery.TFPopulation') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
end