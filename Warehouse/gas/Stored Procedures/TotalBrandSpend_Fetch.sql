-- =============================================
-- Author:		JEA
-- Create date: 28/01/2013
-- Description:	Fetches total brand spend as
-- refreshed monthly.
-- =============================================
CREATE PROCEDURE [gas].[TotalBrandSpend_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT 'All Transactions' AS TranGroup 
		, bsg.GroupName as [Sector Group]
		, bs.SectorName as Sector
		, b.BrandName AS Brand
		, t.BrandID AS [Brand ID]
		, t.Amount As [Total Spend]
		, T.TransCount AS [Trans Count]
		, t.CustomerCount as [Customer Count]
	FROM Relational.TotalBrandSpend T
	INNER JOIN Relational.Brand b on t.BrandID = b.BrandID
	INNER JOIN Relational.BrandSector bs on b.SectorID = bs.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg on bs.SectorGroupID = bsg.SectorGroupID
	
	UNION
	
	SELECT 'All Transactions' AS TranGroup 
		, NULL as [Sector Group]
		, NULL as Sector
		, 'GRAND TOTAL' AS Brand
		, NULL AS [Brand ID]
		, t.Amount As [Total Spend]
		, T.TransCount AS [Trans Count]
		, t.CustomerCount as [Customer Count]
	FROM Relational.TotalBrandSpend T
	WHERE t.brandid = 0

	UNION

	SELECT 'Online Transactions' AS TranGroup 
		, bsg.GroupName as [Sector Group]
		, bs.SectorName as Sector
		, b.BrandName AS Brand
		, t.BrandID AS [Brand ID]
		, t.Amount As [Total Spend]
		, T.TransCount AS [Trans Count]
		, t.CustomerCount as [Customer Count]
	FROM Relational.TotalBrandSpendOnline T
	INNER JOIN Relational.Brand b on t.BrandID = b.BrandID
	INNER JOIN Relational.BrandSector bs on b.SectorID = bs.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg on bs.SectorGroupID = bsg.SectorGroupID
	
	UNION
	
	SELECT 'Online Transactions' AS TranGroup 
		, NULL as [Sector Group]
		, NULL as Sector
		, 'GRAND TOTAL' AS Brand
		, NULL AS [Brand ID]
		, t.Amount As [Total Spend]
		, T.TransCount AS [Trans Count]
		, t.CustomerCount as [Customer Count]
	FROM Relational.TotalBrandSpendOnline T
	WHERE t.brandid = 0
	
	ORDER BY [Total Spend] desc
    
END
GO
GRANT EXECUTE
    ON OBJECT::[gas].[TotalBrandSpend_Fetch] TO [DB5\reportinguser]
    AS [dbo];

