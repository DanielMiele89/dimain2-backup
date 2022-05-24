

/*=================================================================================================
Author: Shaun H
Purpose: Pulls all the relevant gender data for population
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Gender]
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

	-- Find Population Genders
	Select	p.id
			,c.gender
	Into	#gender
	From	#Population p
	Join	Relational.CINList cl on cl.CINID=p.ID
	Join	Relational.customer c on cl.CIN=c.sourceUID

	Select		distinct(p.id) as id
				,case 
					when g.gender is null then 'U' 
					else g.Gender 
				end as gender
	From		#Population p
	Left Join	#gender g on g.ID=p.ID
	Order By	p.id asc

END
