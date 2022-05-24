
/*=================================================================================================
Uploading the Data from Excel
Part 1: Getting Natural Sales OUTPUT
Version 1: 
=================================================================================================*/

CREATE PROCEDURE  [ExcelQuery].[ROCPhase2Forecast_BrandOUT_Seasonal] AS

SELECT DISTINCT
  monthid2,
  OS.brandid,
  Sales_adj,
  Spender_adj,
  avgw_sales,
  avgw_spder,
  avgw_Sales_BASE,
  avgw_Spender_BASE,
  Cardholders
FROM Prototype.ROCP2_SegFore_OutputSeasonal OS
INNER JOIN ExcelQuery.ROCPhase2Forecast_DownloadBrand b on OS.BrandID=b.BrandID
WHERE monthid2 NOT IN (SELECT DISTINCT
  season_ID
FROM Prototype.ROCP2_SeasonBuild) 
ORDER BY OS.brandid, monthid2