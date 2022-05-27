﻿

/*=================================================================================================
Author: Shaun H
Purpose: Produce another feature for algorithm testing framework - Frequency of Transactions
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[TestingFramework_SectorFrequency]	
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
	
	-- Define sector & retrieve ConsumerCombinationIDs
	Declare @SectorID int = (Select SectorID From Warehouse.Relational.Brand Where BrandID = @BrandID)

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	Select		distinct ConsumerCombinationID
	Into		#CC
	From		Relational.ConsumerCombination cc
	Join		Relational.Brand b on b.brandid = cc.brandid
	Where		b.SectorID = @SectorID
			and IsUKSpend = 1

	CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #cc(ConsumerCombinationID)

	-- Find sector Frequency for each CINID
	IF OBJECT_ID('tempdb..#spend') IS NOT NULL DROP TABLE #spend
	Select		ct.CINID
				,count(Amount) as Frequency
	Into		#spend
	From		Relational.ConsumerTransaction ct with (nolock)
	Join		#Population p on p.ID=ct.cinid
	Join		#CC cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
	Where		@StartDate <= TranDate and TranDate <= @enddate 
			and	ct.IsRefund = 0
	Group By	ct.CINID

	Select		distinct p.id as id
				,case 
					when s.Frequency is null then 0
					else s.Frequency
				end as Frequency
	From		#Population p
	Left Join	#spend s on s.CINID=p.ID
	Order By	p.ID asc

END