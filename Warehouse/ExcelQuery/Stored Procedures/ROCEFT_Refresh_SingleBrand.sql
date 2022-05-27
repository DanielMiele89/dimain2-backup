-- =============================================
-- Author:		Beyers Geldenhuys
-- Create date: 20/06/2017
-- Description:	Stored procedure to refresh all tables for the ROCEFT background data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_Refresh_SingleBrand]
	(
		@BrandID INT
	)    
AS
IF @BrandID IS NULL
	BEGIN
		PRINT 'This code can only be used for a single brand'
		RETURN
	END 
ELSE
	BEGIN
		SET NOCOUNT ON;

		IF @BrandID IS NOT NULL 
		BEGIN
			EXEC Warehouse.ExcelQuery.ROCEFT_UpdateBrandList @BrandID						
		END
	
		-- Beyers Architecture
		EXEC Warehouse.ExcelQuery.ROCEFT_Cardholder
		EXEC Warehouse.ExcelQuery.ROCEFT_RetailerSegmentationLengths_Calculate @BrandID		
		EXEC Warehouse.ExcelQuery.ROCEFT_NaturalSales_Calculate_v2 @BrandID					
		EXEC Warehouse.ExcelQuery.ROCEFT_RBS_ShopperSegmentSplits_Calculate @BrandID		
		EXEC Warehouse.ExcelQuery.ROCEFT_nFIShopperSegmentSplit_Calculate @BrandID		
		EXEC Warehouse.ExcelQuery.ROCEFT_nFISpendHistory_Calculate_v2				
		EXEC Warehouse.ExcelQuery.ROCEFT_RBS_PmtMethodSplit_Calculate						
		EXEC Warehouse.ExcelQuery.ROCEFT_Seasonality_Calculate @BrandID							
		EXEC Warehouse.ExcelQuery.ROCEFT_SpendStretch_Calculate	@BrandID
	
		-- Architecture agnostic
		EXEC Warehouse.ExcelQuery.ROCEFT_CardMix

		-- Shaun Architecture
		EXEC Warehouse.ExcelQuery.ROCEFT_CumulGainsBase @BrandID
		EXEC Warehouse.ExcelQuery.ROCEFT_Heatmap		-- Backed up to Sandbox.Shaun (Just in case)
		EXEC Warehouse.ExcelQuery.ROCEFT_CumulGainsRBS	-- Backed up to Sandbox.Shaun (Just in case)
		EXEC Warehouse.ExcelQuery.ROCEFT_CumulGainsROC	-- Backed up to Sandbox.Shaun (Just in case)
		EXEC Warehouse.ExcelQuery.ROCEFT_DecayRate		-- Backed up to Sandbox.Shaun (Just in case)
	
		-- ETL Process to port to RewardBI
		EXEC MI.ROCForecastingTool_ETL_StartJob 

 
	END
