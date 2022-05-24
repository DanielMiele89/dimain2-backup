

/*=================================================================================================
Sales Visualisation Refresh
Version 1: A. Devereux 25/02/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 1 Hour

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Cameo_Code_Group]
	(@poptable varchar(max))
AS
BEGIN
	SET NOCOUNT ON;

	EXEC('	
	SELECT	* 
	INTO	#Population
	FROM ' + @poptable +  '
	
	Select	p.id
			,cc.CAMEO_CODE_GROUP
	Into	#CAMEO_CODE_GROUP
	From	#Population p
	Join	Relational.CINList cl on cl.CINID=p.ID
	Join	Relational.customer c on cl.CIN=c.sourceUID
	Join	Relational.CAMEO cam on cam.Postcode=c.PostCode
	Join	Relational.CAMEO_code cc on cam.CAMEO_CODE=cc.CAMEO_CODE

	Select		distinct(p.id) as id
				,(case when g.CAMEO_CODE_GROUP is null then
					''U'' 
				 else 
					g.CAMEO_CODE_GROUP
				end) as CAMEO_CODE_GROUP
	From		#Population p
	Left Join	#CAMEO_CODE_GROUP g on g.ID=p.ID
	Order By	p.id asc
	')

	-- Old Code
	--EXEC('	If object_ID(''Warehouse.ExcelQuery.TFPopulation'') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
	--SELECT * 
	--INTO Warehouse.ExcelQuery.TFPopulation
	--FROM ' + @poptable +  '
	
	--')

	--select	p.id
	--		,cc.CAMEO_CODE_GROUP
	--into	#CAMEO_CODE_GROUP
	--from ExcelQuery.TFPopulation p
	--join Relational.CINList cl on cl.CINID=p.ID
	--join Relational.customer c on cl.CIN=c.sourceUID
	--join Relational.CAMEO cam on cam.Postcode=c.PostCode
	--join Relational.CAMEO_code cc on cam.CAMEO_CODE=cc.CAMEO_CODE

	--select	distinct(p.id) as id
	--		,(case when g.CAMEO_CODE_GROUP is null then 'U' else g.CAMEO_CODE_GROUP end) as CAMEO_CODE_GROUP
	--from ExcelQuery.TFPopulation p
	--left join #CAMEO_CODE_GROUP g on g.ID=p.ID
	--order by p.id asc

	--If object_ID('Warehouse.ExcelQuery.TFPopulation') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
end