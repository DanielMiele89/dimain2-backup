-- =============================================
-- Author:		JEA
-- Create date: 27/02/2013
-- Description:	Comparative list of brand acquirer patterns
-- =============================================
CREATE PROCEDURE [gas].[MIDOriginatorBrandAcquirers_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @CurrentMOMRun int, @PreviousMOMRun int

	SELECT @CurrentMOMRun = MAX(MOMRun) FROM staging.BrandAcquirer
	SELECT @PreviousMOMRun = MAX(MOMRun) FROM staging.BrandAcquirer WHERE MOMRun < @CurrentMOMRun
	
	SELECT COALESCE(C.Brand, P.Brand) AS Brand
		, COALESCE(C.Acquirer, P.Acquirer) AS Acquirer
		, ISNULL(C.MIDCount, 0) AS CurrentMIDCount
		, ISNULL(P.MIDCount, 0) AS PreviousMIDCount
	FROM
	(SELECT ba.BrandID, ba.AcquirerID,B.BrandName AS Brand, a.AcquirerName AS Acquirer, ba.BrandMIDCount As MIDCount
		FROM Staging.BrandAcquirer ba
		INNER JOIN Relational.Brand B ON BA.BrandID = B.BrandID
		INNER JOIN Relational.Acquirer A ON BA.AcquirerID = a.AcquirerID
		WHERE MOMRun = @CurrentMOMRun) C
	FULL OUTER JOIN
	(SELECT ba.BrandID, ba.AcquirerID,B.BrandName AS Brand, a.AcquirerName AS Acquirer, ba.BrandMIDCount As MIDCount
		FROM Staging.BrandAcquirer ba
		INNER JOIN Relational.Brand B ON BA.BrandID = B.BrandID
		INNER JOIN Relational.Acquirer A ON BA.AcquirerID = a.AcquirerID
		WHERE MOMRun = @PreviousMOMRun) P ON C.BrandID = P.BrandID AND C.AcquirerID = P.AcquirerID
	ORDER BY Brand, Acquirer
    
END