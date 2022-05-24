
/*=================================================================================================
Uploading the Data from Excel
Part 1: Getting Natural Sales OUTPUT
Version 1: 
=================================================================================================*/

CREATE PROCEDURE  [ExcelQuery].[ROCPhase2Forecast_BrandOUT_SS] AS

select distinct * 
from Prototype.ROCP2_SSByBrand ss
INNER JOIN ExcelQuery.ROCPhase2Forecast_DownloadBrand b on sS.BrandID=b.BrandID



--SELECT DISTINCT
--  monthid2,
--  OS.brandid,
--  Sales_adj,
--  Spender_adj,
--  avgw_sales,
--  avgw_spder,
--  avgw_Sales_BASE,
--  avgw_Spender_BASE,
--  Cardholders
--FROM Staging.ROCP2_SegFore_OutputSeasonal OS
--INNER JOIN ExcelQuery.ROCPhase2Forecast_DownloadBrand b on OS.BrandID=b.BrandID
--WHERE monthid2 NOT IN (SELECT DISTINCT
--  season_ID
--FROM Staging.ROCP2_SeasonBuild) 
--ORDER BY OS.brandid, monthid2