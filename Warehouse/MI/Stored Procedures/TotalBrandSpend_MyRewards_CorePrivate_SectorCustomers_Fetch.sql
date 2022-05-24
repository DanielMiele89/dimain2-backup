-- =============================================
-- Author:		JEA
-- Create date: 20/10/2016
-- Description:	Sources customer sector totals for the Total Brand Spend report - CorePrivate version
-- =============================================
CREATE PROCEDURE MI.TotalBrandSpend_MyRewards_CorePrivate_SectorCustomers_Fetch 
	(
		@IsPrivate BIT
	)
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
			FROM MI.TotalBrandSpend_MyRewards_CorePrivate t
			INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
			WHERE IsPrivate = @IsPrivate
			GROUP BY b.SectorID) t
	INNER JOIN Relational.BrandSector bs ON t.SectorID = BS.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg ON bs.SectorGroupID = bsg.SectorGroupID
	INNER JOIN MI.SectorTotalCustomers_MyRewards_CorePrivate S ON T.SectorID = S.SectorID
	WHERE S.IsPrivate = @IsPrivate

END