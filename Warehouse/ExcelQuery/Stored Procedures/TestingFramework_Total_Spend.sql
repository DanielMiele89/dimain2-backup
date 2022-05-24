

/*=================================================================================================
Author: Shaun H
Purpose: Retrieve total spend in the defined time period for the defined population
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Total_Spend]	
	(@poptable varchar(100)
	,@startdate varchar(10)
	,@enddate varchar(10))
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

	-- Find all ConsumerCombinationIDs
	If Object_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	Select		distinct ConsumerCombinationID
	Into		#CC
	From		Relational.ConsumerCombination cc
	Where		IsUKSpend = 1

	CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)

	-- Find Total Spend
	IF OBJECT_ID('tempdb..#spend') IS NOT NULL DROP TABLE #spend
	CREATE TABLE #spend
		(
			CINID int
			,spend money
		)

	INSERT INTO #spend
		EXEC ('
				Select		ct.CINID
							,sum(Amount) as spend
				From		Relational.ConsumerTransaction ct with (nolock)
				Join		#Population p on p.ID=ct.cinid
				Join		#CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		''' + @startDate + ''' <= TranDate and TranDate <= ''' + @enddate + '''
				and			ct.IsRefund = 0
				Group By	ct.CINID
			 ')
	

	Select		distinct p.id as id
				,case 
					when s.spend is null then 0
					else s.spend
				end as spend
	From		#Population p
	Left Join	#spend s on s.CINID=p.ID
	Order By	p.ID asc

END