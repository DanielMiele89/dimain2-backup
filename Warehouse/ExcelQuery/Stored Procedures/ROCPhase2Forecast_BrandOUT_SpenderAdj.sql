
/*=================================================================================================
Uploading the Data from Excel
Part 1: Getting Natural Sales OUTPUT
Version 1: 
=================================================================================================*/

CREATE PROCEDURE  [ExcelQuery].[ROCPhase2Forecast_BrandOUT_SpenderAdj] AS

SELECT sa.BrandID
,WeekLength
,ATFRatio
FROM Prototype.ROCP2_SpendersAdj sa
INNER JOIN ExcelQuery.ROCPhase2Forecast_DownloadBrand b on sa.BrandID=b.BrandID