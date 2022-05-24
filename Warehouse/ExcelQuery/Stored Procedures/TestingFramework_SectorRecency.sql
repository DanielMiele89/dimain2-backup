

/*=================================================================================================
Author: Shaun H
Purpose: Derive the Recency of Transaction for a set population (within a defined period)
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[TestingFramework_SectorRecency]	
	(
		@poptable varchar(max)
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
	
	Declare @SectorID int = (Select SectorID From Warehouse.Relational.Brand Where BrandID = @BrandID)

	-- ConsumerCombinationIDs
	IF OBJECT_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc
	Select		distinct ConsumerCombinationID
	Into		#cc
	From		Relational.ConsumerCombination cc
	Join		Relational.Brand b on b.brandid = cc.brandid
	Where		b.SectorID = @SectorID
			and IsUKSpend = 1

	CREATE CLUSTERED INDEX ix_CCID on #cc(ConsumerCombinationID)

	IF OBJECT_ID('tempdb..#spend') IS NOT NULL DROP TABLE #spend
	Select		ct.CINID
				,DATEDIFF(DAY,@EndDate,max(TranDate)) as Recency
	Into		#spend
	From		Relational.ConsumerTransaction ct with (nolock)
	Join		#Population p on p.ID=ct.cinid
	Join		#cc cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
	Where		@StartDate <= TranDate and TranDate <= @EndDate 
			and	ct.IsRefund = 0
	Group By	ct.CINID

	Select		distinct p.id as id
				,case
					when s.Recency is null then DATEDIFF(DAY,@EndDate,@StartDate)
					else s.Recency
				end as Recency
	From		#Population p
	Left Join	#spend s on s.CINID=p.ID
	Order By	p.ID asc

END