
/*=================================================================================================
-- Running for a single brand : Not already available in the excel data - run through excel
Part 1: Run the Exec processes
Version 1: 
=================================================================================================*/



CREATE PROCEDURE [ExcelQuery].[ROCPhase2Forecast_RunSingleBrand]

AS
BEGIN

	SET NOCOUNT ON;


DECLARE @BRANDRUN INT
set @BRANDRUN =(select top 1 * from ExcelQuery.ROCPhase2Forecast_DownloadBrand)


EXEC Warehouse.Prototype.ROCP2_Code_01_CustsDatesBrands @BRANDRUN --BrandID is Single Run “blank” if all Brands
EXEC Warehouse.Prototype.ROCP2_Code_02_FindNaturalSales 1 -- BIT Field (1 if you want this for an individual brand - 0 for all brands)
EXEC Warehouse.Prototype.ROCP2_Code_02B_SeasonalityAdjustment 1 -- BIT Field (1 if you want this for an individual brand - 0 for all brands)

EXEC Warehouse.Prototype.ROCP2_Code_02D_SSAdjustments 1 -- BIT Field (1 if you want this for an individual brand - 0 for all brands)
EXEC Warehouse.Prototype.ROCP2_Code_02E_SpenderAdjustments 1 -- BIT Field (1 if you want this for an individual brand - 0 for all brands)
EXEC Warehouse.Prototype.ROCP2_Code_03_NaturalSalesPublisher_Output 1 -- BIT Field (1 if you want this for an individual brand - 0 for all brands)

END