-- =============================================
-- Author:		Shaun Hide
-- Create date: 2016-11-28
-- Description:	PullData
-- =============================================
CREATE PROCEDURE [ExcelQuery].[PullSalesViz_v6_] 
	-- Add the parameters for the stored procedure here
	@Brand_1 VarChar(50)
	,@Brand_2 VarChar(50)
	,@Brand_3 VarChar(50)
	,@Brand_4 VarChar(50)
	,@Brand_5 VarChar(50)
	,@Brand_6 VarChar(50)
	,@Brand_7 VarChar(50)
	,@Brand_8 VarChar(50)
	,@Brand_9 VarChar(50)
	,@Brand_10 VarChar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	Select *
	From Warehouse.ExcelQuery.SalesVisSuite_Data_v6_
	Where BrandName in (@Brand_1
						,@Brand_2
						,@Brand_3
						,@Brand_4
						,@Brand_5
						,@Brand_6
						,@Brand_7
						,@Brand_8
						,@Brand_9
						,@Brand_10)
	Order By	BrandName
				,Year
				,MonthNum
END