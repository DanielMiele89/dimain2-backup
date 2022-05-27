-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Sets UK combinations
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_UKCombos_Set] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #ukCombos(BrandCombinationID INT PRIMARY KEY
		, MID VARCHAR(50) NOT NULL
		, Narrative VARCHAR(50) NOT NULL
		, MCCID SMALLINT NOT NULL
		, LocationCountry VARCHAR(3) NOT NULL
		, OriginatorID VARCHAR(11) NOT NULL
		, IsHighVariance BIT NOT NULL)

	INSERT INTO #ukCombos(BrandCombinationID, MID, Narrative, MCCID, LocationCountry, OriginatorID, IsHighVariance)
	SELECT ConsumerCombinationID 
		, MID
		, Narrative
		, MCCID
		, LocationCountry
		, OriginatorID
		, IsHighVariance
	FROM Relational.ConsumerCombination
	WHERE BrandMIDID != 147179
	AND BrandMIDID != 142652

	CREATE INDEX IX_TMP_ukCombos ON #ukCombos(MID, Narrative, MCCID, LocationCountry, OriginatorID, BrandCombinationID, IsHighVariance)

	UPDATE Staging.ConsumerTransactionWorking
	SET BrandCombinationID = f.BrandCombinationID
	FROM Staging.ConsumerTransactionWorking h
	INNER JOIN #ukCombos f
		ON h.MID = f.MID
		AND h.Narrative = f.Narrative
		AND h.MCCID = f.MCCID
		AND h.LocationCountry = f.LocationCountry
		AND h.OriginatorID = f.OriginatorID
	WHERE f.IsHighVariance = 0
		AND h.BrandCombinationID IS NULL

	UPDATE Staging.ConsumerTransactionWorking
	SET BrandCombinationID = f.BrandCombinationID
	FROM Staging.ConsumerTransactionWorking h
	INNER JOIN #ukCombos f
		ON h.MID = f.MID
		AND h.Narrative LIKE f.Narrative
		AND h.MCCID = f.MCCID
		AND h.LocationCountry = f.LocationCountry
		AND h.OriginatorID = f.OriginatorID
	WHERE f.IsHighVariance = 1
		AND h.BrandCombinationID IS NULL

	DROP TABLE #ukCombos

END
