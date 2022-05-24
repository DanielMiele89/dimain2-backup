-- =============================================
-- Author:		JEA
-- Create date: 28/05/2014
-- Description:	Returns the acquirer matched MID list
-- =============================================
CREATE PROCEDURE [MI].[MIDOriginatorMatchList_Fetch]
	(
		@AcquirerID TINYINT
	)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @CurrentMOMRun DATETIME

	SELECT @CurrentMOMRun = MAX(RunDate) FROM MI.MOMBrandAcquirerCount

	DECLARE @AcquirerMatch TABLE(BrandID SmallInt PRIMARY KEY, AcquirerID TINYINT NOT NULL, Acquirer varchar(50))

	INSERT INTO @AcquirerMatch(BrandID, AcquirerID, Acquirer)
	SELECT T.BrandID, T.AcquirerID, A.AcquirerName
	FROM
	(
		SELECT BrandID, CASE WHEN Frequency > 1 THEN 8 ELSE AcquirerID END AS AcquirerID
		FROM
		(
			SELECT BrandID, MAX(AcquirerID) AS AcquirerID, COUNT(1) As Frequency
			FROM MI.MOMBrandAcquirerCount
			WHERE RunDate = @CurrentMOMRun AND BrandID != 944
			GROUP BY BrandID
		) T
	) T
	INNER JOIN Relational.Acquirer A ON T.AcquirerID = A.AcquirerID

	SELECT b.BrandID
		, b.BrandName AS Brand
		, m.ConsumerCombinationID
		, m.MID
		, m.Narrative
		, m.LastTranDate
		, m.LocationAddress
		, m.OriginatorID
		, MC.MCC
		, MC.MCCDesc
		, a.AcquirerName As Acquirer
		, CASE WHEN M.BrandID = 944 THEN a.AcquirerName ELSE am.Acquirer END as AcquirerTab 
	FROM MI.MOMCombinationAcquirer M WITH (NOLOCK)
	INNER JOIN Relational.Brand B ON m.BrandID = B.BrandID
	INNER JOIN Relational.Acquirer A on M.AcquirerID = A.AcquirerID
	LEFT OUTER JOIN @AcquirerMatch AM on M.BrandID = AM.BrandID
	INNER JOIN Relational.MCCList MC ON M.MCCID = MC.MCCID
	WHERE (b.BrandID = 944 and a.AcquirerID = @AcquirerID) OR am.AcquirerID = @AcquirerID
	ORDER BY AcquirerTab,BrandID, MID, Narrative, LastTranDate
	
END