-- =============================================
-- Author:		JEA
-- Create date: 27/05/2014
-- Description:	Sources customer sector totals for the Total Brand Spend report - CBP version
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_CBP_SectorCustomers_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT bsg.GroupName As SectorGroup
		, bs.SectorName AS Sector
		, bs.SectorID
		, t.Spend
		, t.TranCount
		, s.CustomerCountThisYear AS CustomerCount
	FROM (SELECT b.SectorID, SUM(SpendThisYear) As Spend
			, SUM(TranCountThisYear) AS TranCount 
			FROM MI.TotalBrandSpend_CBP t
			INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
			GROUP BY b.SectorID) t
	INNER JOIN Relational.BrandSector bs ON t.SectorID = BS.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg ON bs.SectorGroupID = bsg.SectorGroupID
	INNER JOIN MI.SectorTotalCustomers_CBP S ON T.SectorID = S.SectorID

END