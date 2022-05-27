

/*=================================================================================================
Sales Visualisation Refresh
Version 1: A. Devereux	25/02/2016
Version 2: S. Hide		24/11/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 1 Hour

CREATE PROCEDURE [ExcelQuery].[Sales_Vis_Suite_Refresh]	
		@Sdate Date	 --start date
		,@Edate Date --end date
AS
BEGIN
	SET NOCOUNT ON;
-----------  Sales Visualisation Data Extraction -----------------
----------------------------------------------------------------------------------------
----------  Get Consumer Combinations
----------------------------------------------------------------------------------------

	IF object_id('tempdb..#lk_brand') IS NOT NULL DROP TABLE #lk_brand

	Select		b.brandid
				,brandname
				,ConsumerCombinationID
				,BrandGroupID  
	Into		#lk_brand
	From		Warehouse.ExcelQuery.SVSBrands b
	Inner Join	Warehouse.Relational.ConsumerCombination bm 
		On b.[BrandID]=bm.[BrandID]
	Inner Join	Warehouse.Relational.Brand tb 
		On tb.[BrandID] = b.[BrandID]

	-- index... 
	CREATE CLUSTERED INDEX ix_CC ON #lk_brand (ConsumerCombinationID)

----------------------------------------------------------------------------------------
----------  Get Customer Base
----------------------------------------------------------------------------------------
	IF object_id('Warehouse.InsightArchive.SalesVisSuite_FixedBase') IS NOT NULL DROP TABLE Warehouse.InsightArchive.SalesVisSuite_FixedBase
	EXEC Warehouse.Relational.CustomerBase_Generate'SalesVisSuite_FixedBase', @Sdate, @Edate 

---------------------------------------------------------------------------------------
----------  Get Transaction data
---------------------------------------------------------------------------------------
	IF object_id('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions

	Select		BrandName
				,TranDate
				,IsOnline
				,sum(Amount) as sales
				,count(*) as trans  
	Into		#Transactions
	From		Warehouse.Relational.ConsumerTransaction tr with (nolock)
	Inner Join	Warehouse.Insightarchive.SalesVisSuite_FixedBase c
		On tr.[CINID]=c.[CINID]
	Inner Join	#lk_brand lk_b 
		On tr.[ConsumerCombinationID]=lk_b.[ConsumerCombinationID]
	Where		tr.TranDate between @Sdate and @Edate
		AND		0 < Amount
	Group By	BrandName
				,TranDate
				,IsOnline

----------------------------------------------------------------------------------------
----------  Aggregate Transactional Information
----------------------------------------------------------------------------------------
	SET DATEFIRST 1
	IF object_id('Warehouse.ExcelQuery.SalesVisSuite_Data_v5') IS NOT NULL TRUNCATE TABLE Warehouse.ExcelQuery.SalesVisSuite_Data_v5
	
	INSERT INTO		Warehouse.ExcelQuery.SalesVisSuite_Data_v5
		Select 		TranDate
					,TranDate as TranDate_2           -- Whilst not necessary, it makes the pivots far easier
					,DATEPART(wk,TranDate) as WeekNum
					,DATEPART(mm,TranDate) as MonthNum
					,DATEPART(yyyy,TranDate) as Year
					,BrandName
					,sum(sales) as All_sales
					,sum(trans) as All_trans
					,sum(case when isonline=1 then sales else 0 end) as Online_sales
					,sum(case when isonline=1 then trans else 0 end) as Online_trans
					,sum(case when isonline=0 then sales else 0 end) as Store_Sales
					,sum(case when isonline=0 then trans else 0 end) as Store_trans
		From		#Transactions
		GROUP BY	TranDate
					,BrandName
		Order By	BrandName
					,TranDate

	IF object_id('Warehouse.ExcelQuery.SalesVisSuite_Data_v6_') IS NOT NULL TRUNCATE TABLE Warehouse.ExcelQuery.SalesVisSuite_Data_v6_
	INSERT INTO	 Warehouse.ExcelQuery.SalesVisSuite_Data_v6_
		Select 	 DATEPART(mm,TranDate) as MonthNum
				,DATEPART(yyyy,TranDate) as Year
				,cast(left(Convert(varchar,TranDate,112),6) as numeric) as YYYYMM
				,BrandName
				,sum(Sales) as All_sales
				,sum(Trans) as All_trans
				,sum(case when isonline=1 then sales else 0 end) as Online_sales
				,sum(case when isonline=1 then trans else 0 end) as Online_trans
				,sum(case when isonline=0 then sales else 0 end) as Store_Sales
				,sum(case when isonline=0 then trans else 0 end) as Store_trans
		From	#Transactions
		Group By DATEPART(mm,TranDate)
				,DATEPART(yyyy,TranDate)
				,cast(left(Convert(varchar,TranDate,112),6) as numeric)
				,BrandName
		Order By BrandName
				,cast(left(Convert(varchar,TranDate,112),6) as numeric)

		EXEC Warehouse.ExcelQuery.SalesVisData_ETL_StartJob 
END