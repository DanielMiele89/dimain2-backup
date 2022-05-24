
/*=================================================================================================
Uploading the Data from Excel
Part 1: Getting Natural Sales OUTPUT
Version 1: 
=================================================================================================*/

CREATE procedure  [ExcelQuery].[ROCPhase2Forecast_BrandOUT_NaturalSales] AS

select distinct ns.* from  Prototype.ROCP2_NaturalSalesPub_FinalOutput ns
inner join ExcelQuery.ROCPhase2Forecast_DownloadBrand b on ns.BrandID=b.BrandID