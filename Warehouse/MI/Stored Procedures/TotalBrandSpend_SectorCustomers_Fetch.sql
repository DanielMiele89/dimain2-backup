-- =============================================
-- Author:		JEA
-- Create date: 07/02/2014
-- Description:	Sources customer sector totals for the Total Brand Spend report
-- =============================================
CREATE PROCEDURE MI.TotalBrandSpend_SectorCustomers_Fetch 
	
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
			FROM MI.TotalBrandSpend t
			INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
			GROUP BY b.SectorID) t
	INNER JOIN Relational.BrandSector bs ON t.SectorID = BS.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg ON bs.SectorGroupID = bsg.SectorGroupID
	INNER JOIN MI.SectorTotalCustomers S ON T.SectorID = S.SectorID

END