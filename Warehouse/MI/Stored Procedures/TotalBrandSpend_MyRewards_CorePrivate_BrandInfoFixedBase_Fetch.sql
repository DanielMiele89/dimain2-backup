-- =============================================
-- Author:		JEA
-- Create date: 20/10/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_MyRewards_CorePrivate_BrandInfoFixedBase_Fetch] 
	(
		@IsPrivate BIT
	)
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
	FROM MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate t
	INNER JOIN Relational.Brand b on t.BrandID = b.BrandID
	INNER JOIN Relational.BrandSector bs ON B.SectorID = BS.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg ON bs.SectorGroupID = bsg.SectorGroupID
	INNER JOIN (SELECT b.SectorID
				, SUM(SpendThisYear) As SectorSpendThisYear
				, SUM(SpendLastYear) As SectorSpendLastYear 
			FROM MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate t
			INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
			WHERE t.IsPrivate = @IsPrivate
			GROUP BY b.SectorID) s ON b.SectorID = s.SectorID
	INNER JOIN (SELECT b.SectorID
				, SUM(OnlineSpendThisYear) As OnlineSectorSpendThisYear
				, SUM(OnlineSpendLastYear) As OnlineSectorSpendLastYear
			FROM MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate t
			INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
			WHERE t.IsPrivate = @IsPrivate
			GROUP BY b.SectorID) o ON b.SectorID = o.SectorID
	WHERE t.IsPrivate = @IsPrivate

END
