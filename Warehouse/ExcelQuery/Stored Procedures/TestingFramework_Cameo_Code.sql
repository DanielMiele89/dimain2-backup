

/*=================================================================================================
Testing Framework - Cameo_Code pull
Created 05/01/2017 by Alan
Extensively Modified by Shaun 31/05/2017
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Cameo_Code]
	(@poptable varchar(max))
AS
BEGIN
	SET NOCOUNT ON;

	-- Select population into temp table
	IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
	CREATE TABLE #Population
		(
			id int
		)

	INSERT INTO #Population
		EXEC ('
				SELECT	*
				FROM	' + @poptable + '
			 ')
	
	CREATE CLUSTERED INDEX ix_ID ON #Population(ID)

	-- Find the Cameo Code

	IF OBJECT_ID('tempdb..#cameo_list') IS NOT NULL DROP TABLE #cameo_list
	Select		cameo_code
				,ROW_NUMBER() OVER (ORDER BY (cameo_code)) AS cameo_number
	Into		#cameo_list
	From		Relational.cameo
	Group By	cameo_code
	
	IF OBJECT_ID('tempdb..#cameo_code') IS NOT NULL DROP TABLE #cameo_code
	Select	p.id
			,l.cameo_number
	Into	#cameo_code
	From	#Population p
	Join	Relational.CINList cl on cl.CINID=p.ID
	Join	Relational.customer c on cl.CIN=c.sourceUID
	Join	Relational.CAMEO cam on cam.Postcode=c.PostCode
	Join	#cameo_list l on l.cameo_code = cam.cameo_code
	
	Select		distinct(p.id) as id
				,(case when g.cameo_number is null then
					30 
				else 
					g.cameo_number
				end) as cameo_code
	From		#Population p
	Left Join	#cameo_code g on g.ID=p.ID
	Order By	p.id asc	

END