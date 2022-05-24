-- =============================================
-- Author:		JEA
-- Create date: 28/05/2014
-- Description:	Comparative list of brand acquirer patterns
-- =============================================
CREATE PROCEDURE [MI].[MIDOriginatorBrandAcquirerCount_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @CurrentMOMRun DATETIME, @PreviousMOMRun DATETIME

	SELECT @CurrentMOMRun = MAX(RunDate) FROM MI.MOMBrandAcquirerCount
	SELECT @PreviousMOMRun = MAX(RunDate) FROM MI.MOMBrandAcquirerCount WHERE RunDate < @CurrentMOMRun
	
	SELECT COALESCE(C.Brand, P.Brand) AS Brand
		, COALESCE(C.Acquirer, P.Acquirer) AS Acquirer
		, ISNULL(C.CombinationCount, 0) AS CurrentCombinationCount
		, ISNULL(P.CombinationCount, 0) AS PreviousCombinationCount
	FROM
	(SELECT ba.BrandID, ba.AcquirerID,B.BrandName AS Brand, a.AcquirerName AS Acquirer, ba.CombinationCount
		FROM MI.MOMBrandAcquirerCount ba
		INNER JOIN Relational.Brand B ON BA.BrandID = B.BrandID
		INNER JOIN Relational.Acquirer A ON BA.AcquirerID = a.AcquirerID
		WHERE RunDate = @CurrentMOMRun) C
	FULL OUTER JOIN
	(SELECT ba.BrandID, ba.AcquirerID,B.BrandName AS Brand, a.AcquirerName AS Acquirer, ba.CombinationCount
		FROM MI.MOMBrandAcquirerCount ba
		INNER JOIN Relational.Brand B ON BA.BrandID = B.BrandID
		INNER JOIN Relational.Acquirer A ON BA.AcquirerID = a.AcquirerID
		WHERE RunDate = @PreviousMOMRun) P ON C.BrandID = P.BrandID AND C.AcquirerID = P.AcquirerID
	ORDER BY Brand, Acquirer
    
END
