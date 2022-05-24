-- =============================================
-- Author:		SH
-- Create date: 05/03/2019
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_Trend_ETLInsightStore_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT		ID,
				CycleStart,
				CycleEnd,
				Seasonality_CycleID,
				BrandID,
				TotalSales,
				InStoreSales,
				OnlineSales,
				TotalTransactions,
				InStoreTransactions,
				OnlineTransactions,
				MinID,
				MaxID
	FROM		Warehouse.ExcelQuery.ROCEFT_Trend

END
