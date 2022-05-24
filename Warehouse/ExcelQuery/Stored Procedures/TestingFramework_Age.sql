

/*=================================================================================================
Testing Framework - Age pull
Created 05/01/2017 by Alan
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Age]
	(@poptable varchar(max))
AS
BEGIN
	SET NOCOUNT ON;

	EXEC('
		SELECT * 
		INTO #Population
		FROM ' + @poptable +  '
		
		SELECT cl.CINID
			  ,c.agecurrent as age
		INTO #allage
		FROM #Population p
		JOIN Relational.CINList cl on cl.CINID=p.ID
		JOIN Relational.customer c on cl.CIN=c.sourceUID

		SELECT avg(age) as avgage
		INTO #avgage
		FROM #allage

		SELECT distinct(id) as id
			   ,(case when a.age is null then 
					(select top 1 avgage from #avgage) 
				else 
					a.age 
				end) as age
		FROM #Population p
		LEFT JOIN #allage a on a.CINID=p.id
		ORDER BY p.id asc
		')

	-- Old Code (Working v1)
	--EXEC('	If object_ID(''Warehouse.ExcelQuery.TFPopulation'') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
	--	SELECT * 
	--	INTO Warehouse.ExcelQuery.TFPopulation
	--	FROM ' + @poptable +  '')
	
	--select	cl.CINID
	--		,c.agecurrent as age
	--into	#allage
	--from ExcelQuery.TFPopulation p
	--join Relational.CINList cl on cl.CINID=p.ID
	--join Relational.customer c on cl.CIN=c.sourceUID

	--select avg(age) as avgage
	--into #avgage
	--from #allage

	--select	distinct(id) as id
	--		,(case when a.age is null then (select top 1 avgage from #avgage) else a.age end) as age
	--from ExcelQuery.TFPopulation p
	--left join #allage a on a.CINID=p.id
	--order by p.id asc

	--If object_ID('Warehouse.ExcelQuery.TFPopulation') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
end