-- =============================================
-- Author:		JEA
-- Create date: 17/02/2013
-- Description:	Sets BrandCombinationID for the 
-- population of the Big Payment Data Warehouse
-- =============================================
CREATE PROCEDURE gas.BrandCombinationID_Set 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @FileID INT, @MaxRowNum INT, @StartID INT, @EndID INT, @Increment INT

	SELECT @FileID = MIN(FileID) FROM Staging.CardTransactionHolding

	SET @Increment = 500000

	CREATE TABLE #NonPaypalNonForeign(BrandCombinationID INT PRIMARY KEY, BrandMIDID INT, MCCID SMALLINT, OriginatorID VARCHAR(11))

	INSERT INTO #NonPaypalNonForeign(BrandCombinationID, BrandMIDID, MCCID, OriginatorID)
	SELECT ConsumerCombinationID, BrandMIDID, MCCID, OriginatorID
	FROM Relational.ConsumerCombination
	WHERE BrandMIDID != 147179
	AND BrandMIDID != 142652

	CREATE INDEX IX_TMP_NPNF ON #NonPaypalNonForeign(BrandMIDID, MCCID, OriginatorID)

	WHILE @FileID IS NOT NULL
	BEGIN

		SELECT @MaxRowNum = MAX(RowNum) FROM Staging.CardTransactionHolding WHERE FileID = @FileID
		SET @StartID = 1
		SET @EndID = @Increment

		WHILE @StartID < @MaxRowNum
		BEGIN

			UPDATE Staging.CardTransactionHolding
			SET BrandCombinationID = n.BrandCombinationID
			FROM Staging.CardTransactionHolding h
			INNER JOIN #NonPaypalNonForeign n
				ON h.BrandMIDID = n.BrandMIDID AND h.MCCID = n.MCCID AND h.OriginatorID = n.OriginatorID
			WHERE h.FileID = @FileID AND h.RowNum BETWEEN @StartID AND @EndID

			SET @StartID = @StartID + @Increment
			SET @EndID = @EndID + @Increment

		END

		SELECT @FileID = MIN(FileID)
		FROM Staging.CardTransactionHolding
		WHERE FileID > @FileID

	END

	DROP TABLE #NonPaypalNonForeign

END