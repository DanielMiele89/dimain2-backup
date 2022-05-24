-- =============================================
-- Author:		JEA
-- Create date: 11/02/2014
-- Description:	Sources brand-level information for the Total Brand Spend report
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_BrandInfoFixedBase_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT bsg.GroupName As SectorGroup
		, bs.SectorName AS Sector
		, bs.SectorID
		, b.BrandID
		, b.BrandName
		, t.SpendThisYear
		, t.TranCountThisYear
		, t.CustomerCountThisYear
		, t.OnlineSpendThisYear
		, t.OnlineTranCountThisYear
		, t.OnlineCustomerCountThisYear
		, t.SpendLastYear
		, t.TranCountLastYear
		, t.CustomerCountLastYear
		, t.OnlineSpendLastYear
		, t.OnlineTranCountLastYear
		, t.OnlineCustomerCountLastYear
		, s.SectorSpendThisYear
		, o.OnlineSectorSpendThisYear
		, s.SectorSpendLastYear
		, o.OnlineSectorSpendLastYear
	FROM MI.TotalBrandSpendFixedBase t
	INNER JOIN Relational.Brand b on t.BrandID = b.BrandID
	INNER JOIN Relational.BrandSector bs ON B.SectorID = BS.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg ON bs.SectorGroupID = bsg.SectorGroupID
	INNER JOIN (SELECT b.SectorID
				, SUM(SpendThisYear) As SectorSpendThisYear
				, SUM(SpendLastYear) As SectorSpendLastYear 
			FROM MI.TotalBrandSpendFixedBase t
			INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
			GROUP BY b.SectorID) s ON b.SectorID = s.SectorID
	INNER JOIN (SELECT b.SectorID
				, SUM(OnlineSpendThisYear) As OnlineSectorSpendThisYear
				, SUM(OnlineSpendLastYear) As OnlineSectorSpendLastYear
			FROM MI.TotalBrandSpendFixedBase t
			INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
			GROUP BY b.SectorID) o ON b.SectorID = o.SectorID

END
