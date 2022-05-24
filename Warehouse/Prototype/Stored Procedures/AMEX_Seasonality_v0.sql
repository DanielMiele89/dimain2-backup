-- =================================================================================
-- Author:		<Shaun Hide>
-- Create date: <30th March 2017>
-- Description:	<Brand Seasonality>
-- =================================================================================
CREATE PROCEDURE [Prototype].[AMEX_Seasonality_v0]
AS
BEGIN
	SET NOCOUNT ON;
	------------------------------------------------------------------------------
	
	-------------------------------------------------
	--	Date
	-------------------------------------------------

	Declare		@startdate date
	Set			@startdate = (select DATEADD(DAY,1,DATEADD(YEAR,-1,EOMONTH(EndDate))) from Warehouse.Prototype.AMEX_Dates)

	Declare		@enddate date
	Set			@enddate = (select EOMONTH(EndDate) from Warehouse.Prototype.AMEX_Dates)

	-------------------------------------------------
	--	Brand Loop
	-------------------------------------------------
	DECLARE @rowno int
	Set @rowno=1

	WHILE @rowno  <= (select max(rowno) from Warehouse.Prototype.AMEX_RefreshBrand)        
		BEGIN
			---------------------------------------------------------------------------------------------
			-- Create a single brand brand table

			IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
			Select	*
			Into	#Brand
			From	Warehouse.Prototype.AMEX_RefreshBrand
			Where	RowNo = @RowNo
		
			---------------------------------------------------------------------------------------------
			-- Sales Visualisation Suite data pull

			Declare @BrandName varchar(50)
			Set @BrandName = (select BrandName from #Brand)

			Declare @BrandID smallint
			Set @BrandID = (select BrandID from #Brand)

			Declare @Check int
			Set @Check = (select count(*) from Warehouse.ExcelQuery.SalesVisSuite_Data_v5 where BrandName = @BrandName)
		
			If @Check <> 0
				Begin
					Insert Into Warehouse.Prototype.AMEX_Seasonality
						Select		@BrandID as BrandID
									,BrandName
									,Year
									,MonthNum
									,sum(All_Sales) as Total_Sales
									,sum(All_Trans) as Total_Trans
									,sum(Online_Sales) as Online_Sales
									,sum(Online_Trans) as Online_Trans
									,sum(Store_Sales) as Store_Sales
									,sum(Store_Trans) as Store_Trans
						From		Warehouse.ExcelQuery.SalesVisSuite_Data_v5
						Where		BrandName = @BrandName
							and		@startdate <= TranDate
							and		TranDate <= @enddate
						Group by	BrandName
									,Year
									,MonthNum
						Order by	BrandName
									,Year
									,MonthNum
				End
			Else
				Begin
					Insert Into Warehouse.Prototype.AMEX_RunIssues
						Select		@BrandID
									,@BrandName
									,'This brand does not exist in sales visualisation suite...'
				End
		
			Set @RowNo = @RowNo + 1
		END

	------------------------------------------------------------------------------
	END