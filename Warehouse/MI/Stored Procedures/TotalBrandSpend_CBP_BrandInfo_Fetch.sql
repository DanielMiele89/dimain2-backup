-- =============================================
-- Author:		JEA
-- Create date: 27/05/2014
-- Description:	Sources brand-level information for the Total Brand Spend report
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_CBP_BrandInfo_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @CurrentMOMRun DATETIME

	SELECT @CurrentMOMRun = MAX(RunDate) FROM MI.MOMBrandAcquirerCount
	
	SELECT ba.BrandID, ba.AcquirerID,B.BrandName AS Brand, a.AcquirerName AS Acquirer, ba.CombinationCount
	INTO #BACombos
		FROM MI.MOMBrandAcquirerCount ba
		INNER JOIN Relational.Brand B ON BA.BrandID = B.BrandID
		INNER JOIN Relational.Acquirer A ON BA.AcquirerID = a.AcquirerID
		WHERE RunDate = @CurrentMOMRun

	CREATE TABLE #BrandAcquirerDisplay(ID SMALLINT PRIMARY KEY IDENTITY
		, BrandID SMALLINT NOT NULL
		, DisplayText VARCHAR(50))

	INSERT INTO #BrandAcquirerDisplay(BrandID, DisplayText)
	SELECT B.BrandID, B.Acquirer
	FROM #BACombos B
	INNER JOIN (SELECT BrandID, COUNT(1) AS Freq
				FROM #BACombos
				GROUP BY BrandID
				HAVING COUNT(1) = 1) F ON B.BrandID = F.BrandID
	
	INSERT INTO #BrandAcquirerDisplay(BrandID, DisplayText)
	SELECT DISTINCT B.BrandID, 'Split Acquirer'
	FROM #BACombos B
	INNER JOIN (SELECT BrandID, COUNT(1) AS Freq
				FROM #BACombos
				GROUP BY BrandID
				HAVING COUNT(1) > 1) F ON B.BrandID = F.BrandID

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
		, t.SectorExclusiveCustomerCountThisYear
		, t.SpendLastYear
		, t.TranCountLastYear
		, t.CustomerCountLastYear
		, t.OnlineSpendLastYear
		, t.OnlineTranCountLastYear
		, t.OnlineCustomerCountLastYear
		, t.SectorExclusiveCustomerCountLastYear
		, s.SectorSpendThisYear
		, o.OnlineSectorSpendThisYear
		, s.SectorSpendLastYear
		, o.OnlineSectorSpendLastYear
		, ISNULL(BAD.DisplayText, CAST('Unknown' AS VARCHAR(50))) AS Acquirer
	FROM MI.TotalBrandSpend_CBP t
	INNER JOIN Relational.Brand b on t.BrandID = b.BrandID
	INNER JOIN Relational.BrandSector bs ON B.SectorID = BS.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg ON bs.SectorGroupID = bsg.SectorGroupID
	LEFT OUTER JOIN #BrandAcquirerDisplay BAD ON t.BrandID = BAD.BrandID
	INNER JOIN (SELECT b.SectorID
				, SUM(SpendThisYear) As SectorSpendThisYear
				, SUM(SpendLastYear) As SectorSpendLastYear 
			FROM MI.TotalBrandSpend_CBP t
			INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
			GROUP BY b.SectorID) s ON b.SectorID = s.SectorID
	INNER JOIN (SELECT b.SectorID
				, SUM(OnlineSpendThisYear) As OnlineSectorSpendThisYear
				, SUM(OnlineSpendLastYear) As OnlineSectorSpendLastYear
			FROM MI.TotalBrandSpend_CBP t
			INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
			GROUP BY b.SectorID) o ON b.SectorID = o.SectorID

END
