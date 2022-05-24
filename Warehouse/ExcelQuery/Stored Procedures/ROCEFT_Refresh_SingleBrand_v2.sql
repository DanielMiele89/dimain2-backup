-- =============================================
-- Author:		Shaun Hide
-- Create date: 28th July 2017
-- Description:	Refresh all the needed tables for ROCEFT Model.
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_Refresh_SingleBrand_v2]
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

		-- Architecture agnostic
		EXEC Warehouse.ExcelQuery.ROCEFT_CardMix
		
		DECLARE @BrandList VARCHAR(500) = (CAST(@BrandID AS VARCHAR))
		EXEC Warehouse.ExcelQuery.ROCEFT_NaturalSalesByCycle_Calculate @BrandList

		-- Beyers Architecture
		EXEC Warehouse.ExcelQuery.ROCEFT_nFIShopperSegmentSplit_Calculate @BrandID		
		EXEC Warehouse.ExcelQuery.ROCEFT_nFISpendHistory_Calculate_v3			
		EXEC Warehouse.ExcelQuery.ROCEFT_RBS_PmtMethodSplit_Calculate
		EXEC Warehouse.ExcelQuery.ROCEFT_SpendStretch_Calculate	@BrandID

		-- Shaun Architecture
		EXEC Warehouse.ExcelQuery.ROCEFT_CumulGainsBase @BrandID
		EXEC Warehouse.ExcelQuery.ROCEFT_Heatmap
		EXEC Warehouse.ExcelQuery.ROCEFT_CumulGainsRBS_v1
		EXEC Warehouse.ExcelQuery.ROCEFT_CumulGainsROC
			
		-- ETL Process to port to RewardBI
		EXEC MI.ROCForecastingTool_ETL_StartJob 

	END
