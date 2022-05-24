

/*=================================================================================================
Sales Visualisation Add Brand
Version 1: S. Hide		13/12/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)

CREATE PROCEDURE [ExcelQuery].[Sales_Vis_Suite_Add_Brand]	
		@BrandID Int -- Brand to be added
AS
BEGIN
	SET NOCOUNT ON;

-----------  Sales Visualisation Data Addition -----------------
-- Declare @BrandID Int
-- Set @BrandID = 2096

----------------------------------------------------------------------------------------
----------  Add brand to the SVSBrands list for future
----------------------------------------------------------------------------------------
	-- Test that we aren't going to introduce duplicates
	Declare @AlreadyExists Int
	Select @AlreadyExists = BrandID From Warehouse.ExcelQuery.SVSBrands Where BrandID = @BrandID
	If @AlreadyExists IS NOT NULL
		Begin
			-- Empty brand from the BrandList		
			Delete From Warehouse.ExcelQuery.SVSBrands Where BrandID = @BrandID
		
			-- Empty brand from the SalesVisSuite_Data tables
			Declare @BrandName varchar(max)
			Set @BrandName = (Select BrandName From Warehouse.Relational.Brand Where BrandID = @BrandID)
			Delete From Warehouse.ExcelQuery.SalesVisSuite_Data_v5 Where BrandName = @BrandName
			Delete From Warehouse.ExcelQuery.SalesVisSuite_Data_v6_ Where BrandName = @BrandName
		End


	Insert into Warehouse.ExcelQuery.SVSBrands
		Select BrandID
		From Warehouse.Relational.Brand
		Where BrandID = @BrandID

	----------------------------------------------------------------------------------------
	----------  Get Consumer Combinations
	----------------------------------------------------------------------------------------

	if object_id('tempdb..#lk_brand') is not null drop table #lk_brand

	select b.brandid
			,tb.brandname
			,bm.ConsumerCombinationID
			,tb.BrandGroupID  
	into #lk_brand
	from			Warehouse.ExcelQuery.SVSBrands b
	inner join		warehouse.relational.ConsumerCombination bm on b.brandid=bm.BrandID
	inner join		warehouse.Relational.Brand tb on tb.BrandID = b.BrandID
	where			b.BrandID = @BrandID

	-- index... 
	CREATE clustered INDEX ix_CC ON #lk_brand (ConsumerCombinationID)

	----------------------------------------------------------------------------------------
	----------  Find the dates in the current base
	----------------------------------------------------------------------------------------
	Declare @SDate Date
	Declare @EDate Date
	Select @SDate = min(TranDate) from Warehouse.ExcelQuery.SalesVisSuite_Data_v5
	Select @EDate = max(TranDate) from Warehouse.ExcelQuery.SalesVisSuite_Data_v5


	---------------------------------------------------------------------------------------
	----------  Get Transaction data
	---------------------------------------------------------------------------------------
		
	EXEC('
		if object_id(''tempdb..#Transactions'') is not null drop table #Transactions
		select		sum(Amount) as sales
					,count(*) as trans
					,BrandName
					,TranDate
					,IsOnline
		into		#Transactions
		from		Warehouse.Relational.ConsumerTransaction tr with (nolock)
		inner join	warehouse.insightarchive.SalesVisSuite_FixedBase c on tr.CINID=c.CINID
		inner join	#lk_brand lk_b on tr.ConsumerCombinationID=lk_b.ConsumerCombinationID  -- in the brands
		where		tr.TranDate between ''' + @Sdate + ''' and ''' + @Edate + '''
				AND	0 < Amount
		GROUP BY	isonline 
					,BrandName
					,TranDate
					,IsOnline

		----------------------------------------------------------------------------------------
		----------  Aggregate Transactional Information
		----------------------------------------------------------------------------------------

		SET DATEFIRST 1
		Insert Into		Warehouse.ExcelQuery.SalesVisSuite_Data_v5
			Select 		TranDate
						,TranDate as TranDate_2
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
		')
END