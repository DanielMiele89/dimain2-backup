-- =============================================
-- Author:		Shaun
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE Prototype.SH_Seasonal 
AS
BEGIN
SELECT
  monthid2,
  brandid,
  Sales_adj,
  Spender_adj,
  avgw_sales,
  avgw_spder,
  avgw_Sales_BASE,
  avgw_Spender_BASE,
  Cardholders
FROM warehouse.Prototype.ROCP2_SegFore_OutputSeasonal
WHERE monthid2 NOT IN (SELECT DISTINCT
  season_ID
FROM warehouse.Prototype.ROCP2_SeasonBuild)
--AND BRANDID in (select distinct brandid from warehouse.prototype.ROCP2_BrandList_ForModel_Individual) 
ORDER BY brandid, monthid2
END