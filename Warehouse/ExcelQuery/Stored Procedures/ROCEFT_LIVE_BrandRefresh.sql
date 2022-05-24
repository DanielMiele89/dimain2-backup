-- =============================================
-- Author:		Shaun Hide
-- Create date: 01/02/2019
-- Description:	Refresh all the needed tables for ROCEFT Model.
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_LIVE_BrandRefresh]
	(
		@BrandList VARCHAR(500)
	)    
AS
IF @BrandList IS NULL
	BEGIN
		PRINT 'This code should not be used to refresh all brands'
		RETURN
	END 
ELSE
	BEGIN
		SET NOCOUNT ON;

		-- General Brand List maintenance
		EXEC [ExcelQuery].[ROCEFT_LIVE_UpdateBrandList] @BrandList
		EXEC [ExcelQuery].[ROCEFT_LIVE_RetailerSegmentationLengths_Calculate] @BrandList

		-- RBS Data Related Stored Procedures
		EXEC [ExcelQuery].[ROCEFT_LIVE_NaturalSalesByCycle_Calculate] @BrandList 
		EXEC [ExcelQuery].[ROCEFT_LIVE_Trend_Calculate] @BrandList
		EXEC [ExcelQuery].[ROCEFT_LIVE_SpendStretch_Calculate] @BrandList 
		EXEC [ExcelQuery].[ROCEFT_LIVE_RBS_CumulativeGains_Calculate] @BrandList 

		-- NFI Data Related Stored Procedures
		EXEC [ExcelQuery].[ROCEFT_LIVE_nFIShopperSegmentSplit_Calculate] @BrandList 
		EXEC [ExcelQuery].[ROCEFT_LIVE_nFISpendHistory_Calculate]
		EXEC [ExcelQuery].[ROCEFT_LIVE_ROC_CumulativeGains_Calculate]

		-- ETL Process to port to RewardBI
		EXEC ExcelQuery.ROCForecastingTool_ETL_StartJob 
	END