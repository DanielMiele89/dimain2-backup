-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[AMEX_NewModel_Spend_Stretch]
	-- Add the parameters for the stored procedure here
@BrandList Varchar(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start - Spend Stretch'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--	Specify Dates
	-------------------------------------------------------------------------------------

	Declare		@startdate date
	Set			@startdate = (select DATEADD(YEAR,0,DATEADD(DAY,1,MIN(CycleStart))) from Warehouse.ExcelQuery.AmexModelNaturalSales)

	Declare		@enddate date
	Set			@enddate = (select MAX(CycleEnd) from Warehouse.ExcelQuery.AmexModelNaturalSales)

	-------------------------------------------------------------------------------------
	--	Pre-Brand Loop Set-up
	-------------------------------------------------------------------------------------

	-- 1.5m Sample
	If Object_ID('tempdb..#MyRewardsBase') IS NOT NULL DROP TABLE #MyRewardsBase
	Select *
	Into #MyRewardsBase
	From (
SELECT			DISTINCT CINID
				,'My Rewards' as Segment
				FROM				Warehouse.Relational.Customer c 
				LEFT OUTER JOIN		(SELECT	DISTINCT FanID
									 FROM	Warehouse.Relational.Customer_RBSGSegments
									 WHERE	StartDate <= GETDATE()
										AND (EndDate IS NULL OR EndDate > GETDATE())
										AND CustomerSegment = 'V') priv
								ON	priv.FanID = c.FanID
				LEFT OUTER JOIN		Warehouse.Relational.CAMEO cam  WITH (NOLOCK)
								ON	c.PostCode = cam.Postcode
				LEFT OUTER JOIN		Warehouse.Relational.CINList cl
								ON	c.SourceUID = cl.CIN
				WHERE			(	priv.FanID IS NOT NULL
								OR  cam.CAMEO_CODE_GROUP IN ('01','02','03','04'))
								AND cl.CINID IS NOT NULL
								AND NOT EXISTS	(
													SELECT	*
													FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup
													WHERE	EndDate IS NULL
														AND c.SourceUID = dup.SourceUID
												)
		  ) a
	order by newid()

	CREATE CLUSTERED INDEX ix_ccID on #MyRewardsBase(CINID)
	-------------------------------------------------------------------------------------
	--	Set for single brand or full refresh
	-------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	CREATE TABLE #BrandList
		(
			BrandID INT NOT NULL PRIMARY KEY
			,BrandName VARCHAR(50)
			,RowNo INT
		)
	
	
	IF @BrandList IS NULL
		Begin	
			Truncate Table Warehouse.Prototype.AMEX_SpendStretch_Model

			INSERT INTO #BrandList
			Select	*,ROW_NUMBER() OVER (order by BrandId) AS RowNo
			From	Warehouse.Prototype.AMEX_BrandList
		End
	IF @BrandList IS NOT NULL
		Begin
			INSERT INTO #BrandList
			Select	BrandID, BrandName,ROW_NUMBER() OVER (order by BrandId) AS RowNo
			From	
			(Select Distinct BrandId, BrandName FROM Warehouse.Relational.Brand
			Where CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0) A

			DELETE 
			FROM Warehouse.Prototype.AMEX_SpendStretch_Model
			Where CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END

	-------------------------------------------------------------------------------------
	--	Begin the loop!!!!!
	-------------------------------------------------------------------------------------
	DECLARE @rowno int
	Set @rowno=1

	WHILE @rowno  <= (select max(rowno) from #BrandList)        
		BEGIN

			SELECT @msg = 'RowNo ' + cast(@RowNo as varchar(3))
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Create a single brand brand table


			IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
			Select	*
			Into	#Brand
			From	#BrandList
			Where	RowNo = @RowNo

			---------------------------------------------------------------------------------------------
			-- BrandID and BrandName variables
		
			Declare @BrandID smallint
			Set @BrandID = (select BrandID from #Brand)

			Declare @BrandName varchar(50)
			Set @BrandName = (select BrandName from #Brand)

			---------------------------------------------------------------------------------------------
			-- Derive ConsumerCombinationIDs
		
			If Object_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc
			Select	br.BrandID
					,cc.ConsumerCombinationID
			Into	#cc
			From	Warehouse.Relational.ConsumerCombination cc
			Join	#Brand br on br.BrandID = cc.BrandID
		
			CREATE CLUSTERED INDEX ix_CCID on #cc(ConsumerCombinationID)
			CREATE INDEX ix_BrandID on #cc(BrandID)

			---------------------------------------------------------------------------------------------
			-- Find 12m Historic Data

			If Object_ID('tempdb..#HistoricSpend') IS NOT NULL DROP TABLE #HistoricSpend
			Select	cc.BrandID
					,ct.CINID
					,ct.Amount
					,ROW_NUMBER() OVER(ORDER BY ct.Amount) as TransNumber
					,ct.TranDate
			Into	#HistoricSpend
			From	Warehouse.Relational.ConsumerTransaction ct with (nolock)
			Join	#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			Join	#MyRewardsBase base on base.CINID = ct.CINID
			Where	@startdate <= TranDate
				and TranDate <= @enddate
				and IsRefund = 0

			---------------------------------------------------------------------------------------------
			-- Build Spend Distribution
			---------------------------------------------------------------------------------------------

			-- 1. Find Distribution of Spend & Trans by ATV (Spender & Trans are virtually identical so Spender can be omitted)
			If Object_ID('tempdb..#ATVTrans0') IS NOT NULL DROP TABLE #ATVTrans0
			Select	FLOOR(1.0*Amount)		as ATV
					,SUM(Amount)			as Spend
					,COUNT(1)				as Trans
			Into	#ATVTrans0
			From	#HistoricSpend tr
			Group by FLOOR(1.0*Amount) 
			Order by FLOOR(1.0*Amount) 

			-- select * from #ATVTrans0 order by ATV
		
			-- 2. Find the total for each metric
			If Object_ID('tempdb..#ATVTrans1') IS NOT NULL DROP TABLE #ATVTrans1
			Select	b.*
					,SUM(Trans) OVER () Total_Trans
					,SUM(Spend) OVER () Total_Spend
			Into #ATVTrans1 
			From #ATVTrans0 b

			CREATE INDEX ix_ATV on #ATVTrans1(ATV)

			-- select * from #ATVTrans1
		
			-- 3. Produce a cumulative percentage table
			If Object_ID('tempdb..#ATVTrans2') IS NOT NULL DROP TABLE #ATVTrans2
			Select  t1.ATV
					,1.0*SUM(t2.Trans)/t1.Total_Trans as Perc_Trans
					,1.0*SUM(t2.Spend)/t1.Total_Spend as Perc_Value
					,t1.Total_Trans
			Into	#ATVTrans2
			From	#ATVTrans1 t1
			Join	#ATVTrans1 t2 on t1.ATV <= t2.ATV 
			Group by t1.ATV
					,t1.Total_Trans
					,t1.Total_Spend
					,t1.Total_Trans

			-- select * from #ATVTrans2

			---------------------------------------------------------------------------------------------
			-- Insert into output table

			--Insert Into	Warehouse.Prototype.AMEX_SpendStretch
			--Truncate Table Warehouse.Prototype.AMEX_SpendStretch_Model
			Insert Into	Warehouse.Prototype.AMEX_SpendStretch_Model
				Select	@BrandID as BrandID,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.00 THEN ATV END),MAX(ATV),0) Trans_p_00,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.05 THEN ATV END),MAX(ATV),0) Trans_p_05,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.10 THEN ATV END),MAX(ATV),0) Trans_p_10,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.15 THEN ATV END),MAX(ATV),0) Trans_p_15,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.20 THEN ATV END),MAX(ATV),0) Trans_p_20,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.25 THEN ATV END),MAX(ATV),0) Trans_p_25,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.30 THEN ATV END),MAX(ATV),0) Trans_p_30,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.35 THEN ATV END),MAX(ATV),0) Trans_p_35,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.40 THEN ATV END),MAX(ATV),0) Trans_p_40,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.45 THEN ATV END),MAX(ATV),0) Trans_p_45,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.50 THEN ATV END),MAX(ATV),0) Trans_p_50,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.55 THEN ATV END),MAX(ATV),0) Trans_p_55,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.60 THEN ATV END),MAX(ATV),0) Trans_p_60,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.65 THEN ATV END),MAX(ATV),0) Trans_p_65,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.70 THEN ATV END),MAX(ATV),0) Trans_p_70,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.75 THEN ATV END),MAX(ATV),0) Trans_p_75,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.80 THEN ATV END),MAX(ATV),0) Trans_p_80,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.85 THEN ATV END),MAX(ATV),0) Trans_p_85,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.90 THEN ATV END),MAX(ATV),0) Trans_p_90,
						COALESCE(MIN(CASE WHEN Perc_Trans <=0.95 THEN ATV END),MAX(ATV),0) Trans_p_95,
						COALESCE(MIN(CASE WHEN Perc_Trans <=1.00 THEN ATV END),MAX(ATV),0) Trans_p_100,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.00 THEN ATV END),MAX(ATV),0) Sales_p_00,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.05 THEN ATV END),MAX(ATV),0) Sales_p_05,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.10 THEN ATV END),MAX(ATV),0) Sales_p_10,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.15 THEN ATV END),MAX(ATV),0) Sales_p_15,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.20 THEN ATV END),MAX(ATV),0) Sales_p_20,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.25 THEN ATV END),MAX(ATV),0) Sales_p_25,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.30 THEN ATV END),MAX(ATV),0) Sales_p_30,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.35 THEN ATV END),MAX(ATV),0) Sales_p_35,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.40 THEN ATV END),MAX(ATV),0) Sales_p_40,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.45 THEN ATV END),MAX(ATV),0) Sales_p_45,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.50 THEN ATV END),MAX(ATV),0) Sales_p_50,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.55 THEN ATV END),MAX(ATV),0) Sales_p_55,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.60 THEN ATV END),MAX(ATV),0) Sales_p_60,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.65 THEN ATV END),MAX(ATV),0) Sales_p_65,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.70 THEN ATV END),MAX(ATV),0) Sales_p_70,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.75 THEN ATV END),MAX(ATV),0) Sales_p_75,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.80 THEN ATV END),MAX(ATV),0) Sales_p_80,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.85 THEN ATV END),MAX(ATV),0) Sales_p_85,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.90 THEN ATV END),MAX(ATV),0) Sales_p_90,
						COALESCE(MIN(CASE WHEN Perc_Value <=0.95 THEN ATV END),MAX(ATV),0) Sales_p_95,
						COALESCE(MIN(CASE WHEN Perc_Value <=1.00 THEN ATV END),MAX(ATV),0) Sales_p_100
				--INTO	Warehouse.Prototype.AMEX_SpendStretch_New_Model
				From	#ATVTrans2 c
		
			OPTION (RECOMPILE)
				


			Set @RowNo = @RowNo + 1
		END

		SELECT @msg = 'End - Spend Stretch'
		EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
END