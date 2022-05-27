

/*=================================================================================================
Author: Shaun H
Purpose: Produce another feature for algorithm testing framework - Frequency of Transactions
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Total_ATV]	
	(
		@poptable varchar(100)
		,@startdate varchar(10)
		,@enddate varchar(10)
		,@brandID int
	)
AS
BEGIN
	SET NOCOUNT ON;

	-- Define Population
	IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
	CREATE TABLE #Population
		(
			ID int
		)

	INSERT INTO #Population
		EXEC ('
				SELECT	ID
				FROM ' + @poptable +  '
			 ')

	CREATE CLUSTERED INDEX ix_ID ON #Population(ID)
	
	-- Retrieve ConsumerCombinationIDs

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	Select		distinct ConsumerCombinationID
	Into		#CC
	From		Relational.ConsumerCombination cc
	Join		Relational.Brand b on b.brandid = cc.brandid
	Where		IsUKSpend = 1

	CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #cc(ConsumerCombinationID)

	-- Find sector Frequency for each CINID
	IF OBJECT_ID('tempdb..#spend') IS NOT NULL DROP TABLE #spend
	Select		ct.CINID
				,coalesce(sum(Amount)/nullif(count(Amount),0),0) as ATV
	Into		#spend
	From		Relational.ConsumerTransaction ct with (nolock)
	Join		#Population p on p.ID=ct.cinid
	Join		#CC cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
	Where		@StartDate <= TranDate and TranDate <= @enddate 
			and	ct.IsRefund = 0
	Group By	ct.CINID

	Select		distinct p.id as id
				,case 
					when s.ATV is null then 0
					else s.ATV
				end as Total_ATV
	From		#Population p
	Left Join	#spend s on s.CINID=p.ID
	Order By	p.ID asc

END