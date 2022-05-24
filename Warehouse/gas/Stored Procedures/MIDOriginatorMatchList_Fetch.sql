-- =============================================
-- Author:		JEA
-- Create date: 26/02/2013
-- Description:	Returns the acquirer matched MID list
-- =============================================
CREATE PROCEDURE [gas].[MIDOriginatorMatchList_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @CurrentMOMRun int

	SELECT @CurrentMOMRun = MAX(MOMRun) from staging.BrandAcquirer

	DECLARE @AcquirerMatch TABLE(BrandID SmallInt PRIMARY KEY, Acquirer varchar(50))

	INSERT INTO @AcquirerMatch(BrandID, Acquirer)
	SELECT T.BrandID, A.AcquirerName
	FROM
	(
		SELECT BrandID, CASE WHEN Frequency > 1 THEN 8 ELSE AcquirerID END AS AcquirerID
		FROM
		(
			SELECT BrandID, MAX(AcquirerID) AS AcquirerID, COUNT(1) As Frequency
			FROM staging.BrandAcquirer
			WHERE MOMRun = @CurrentMOMRun
			GROUP BY BrandID
		) T
	) T
	INNER JOIN Relational.Acquirer A ON T.AcquirerID = A.AcquirerID

	SELECT m.BrandID
		, b.BrandName AS Brand
		, m.MID, m.BrandMIDID
		, m.Narrative
		, m.LastTranDate
		, m.LocationAddress
		, m.OriginatorID
		, m.MCC
		, MC.MCCDesc
		, a.AcquirerName As Acquirer
		, am.Acquirer as AcquirerTab 
	FROM staging.MIDOriginMatch M
	INNER JOIN Relational.Brand B ON M.BrandID = B. BrandID
	INNER JOIN Relational.Acquirer A on M.AcquirerID = A.AcquirerID
	INNER JOIN @AcquirerMatch AM on M.BrandID = AM.BrandID
	INNER JOIN Relational.MCCList MC ON M.MCC = MC.MCC
	ORDER BY AcquirerTab,BrandID, MID, Narrative, LastTranDate
	
END
