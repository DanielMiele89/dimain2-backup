-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.MVP_NaturalSalesByCycle_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT PKID, RunDate, GroupName, BrandID, ID
		, Segment, PropensityRank, EngagementRank
		, [Population], TotalSales, OnlineSales
		, TotalTrans, OnlineTrans, TotalShoppers, OnlineShoppers
	FROM ExcelQuery.MVP_NaturalSalesByCycle

END
