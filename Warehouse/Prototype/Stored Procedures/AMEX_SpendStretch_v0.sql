-- =================================================================================
-- Author:		<Shaun Hide>
-- Create date: <30th March 2017>
-- Description:	<Distribution of Spend & Trans by Ventiles>
-- =================================================================================
CREATE PROCEDURE [Prototype].[AMEX_SpendStretch_v0]
AS
BEGIN
	SET NOCOUNT ON;
	------------------------------------------------------------------------------
	
	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start - Spend Stretch'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--	Specify Dates
	-------------------------------------------------------------------------------------

	Declare		@startdate date
	Set			@startdate = (select DATEADD(YEAR,-1,DATEADD(DAY,1,EndDate)) from Warehouse.Prototype.AMEX_Dates)

	Declare		@enddate date
	Set			@enddate = (select EndDate from Warehouse.Prototype.AMEX_Dates)

	-------------------------------------------------------------------------------------
	--	Pre-Brand Loop Set-up
	-------------------------------------------------------------------------------------

	-- 1.5m Sample
	If Object_ID('tempdb..#MyRewardsBase') IS NOT NULL DROP TABLE #MyRewardsBase
	Select top 1500000 *
	Into #MyRewardsBase
	From (
			Select distinct cl.CINID
							,'My Rewards' as Segment
			From			Relational.Customer c
			Join			Relational.CINList cl 
						 on cl.cin = c.SourceUID		
			Where			c.CurrentlyActive = 1
				and NOT EXISTS
						(	
						Select *
						From Staging.Customer_DuplicateSourceUID dup
						Where EndDate is null
						and	c.SourceUID = dup.SourceUID
						)
		  ) a
	order by newid()

	CREATE CLUSTERED INDEX ix_ccID on #MyRewardsBase(CINID)

	DECLARE @rowno int
	Set @rowno=1

	WHILE @rowno  <= (select max(rowno) from Warehouse.Prototype.AMEX_RefreshBrand)        
		BEGIN

			SELECT @msg = 'RowNo ' + cast(@RowNo as varchar(3))
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Create a single brand brand table

			IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
			Select	*
			Into	#Brand
			From	Warehouse.Prototype.AMEX_RefreshBrand
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

			Insert Into	Warehouse.Prototype.AMEX_SpendStretch
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
				From	#ATVTrans2 c
		
			OPTION (RECOMPILE)
				


			Set @RowNo = @RowNo + 1
		END

		SELECT @msg = 'End - Spend Stretch'
		EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
	------------------------------------------------------------------------------
	END
