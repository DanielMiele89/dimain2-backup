-- =============================================
-- Author:		JEA
-- Create date: 17/02/2014
-- Description:	sets location IDs on staging data
-- =============================================
CREATE PROCEDURE [gas].[LocationID_Set]

AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @FileID INT, @MaxRowNum INT, @StartID INT, @EndID INT, @Increment INT

	SELECT @FileID = MIN(FileID) FROM Staging.CardTransactionHolding

	SET @Increment = 500000

	WHILE @FileID IS NOT NULL
	BEGIN

		SELECT @MaxRowNum = MAX(RowNum) FROM Staging.CardTransactionHolding WHERE FileID = @FileID
		SET @StartID = 1
		SET @EndID = @Increment

		WHILE @StartID < @MaxRowNum
		BEGIN

			UPDATE Staging.CardTransactionHolding
			SET LocationID = n.LocationID
			FROM Staging.CardTransactionHolding h
			INNER JOIN Relational.Location n
				ON h.BrandCombinationID = n.ConsumerCombinationID
			WHERE h.FileID = @FileID AND h.RowNum BETWEEN @StartID AND @EndID
				AND n.IsNonLocational = 1

			UPDATE Staging.CardTransactionHolding
			SET LocationID = n.LocationID
			FROM Staging.CardTransactionHolding h
			INNER JOIN Relational.Location n
				ON h.BrandCombinationID = n.ConsumerCombinationID
				AND h.LocationAddress = n.LocationAddress
			WHERE h.FileID = @FileID AND h.RowNum BETWEEN @StartID AND @EndID

			SET @StartID = @StartID + @Increment
			SET @EndID = @EndID + @Increment

		END --RowNum

		SELECT @FileID = MIN(FileID)
		FROM Staging.CardTransactionHolding
		WHERE FileID > @FileID

	END --FileID

	INSERT INTO Relational.Location(ConsumerCombinationID, LocationAddress, IsNonLocational)
	SELECT DISTINCT BrandCombinationID, LocationAddress, 0
	FROM Staging.CardTransactionHolding
	WHERE LocationID IS NULL
	AND BrandCombinationID IS NOT NULL

	UPDATE Staging.CardTransactionHolding
	SET LocationID = n.LocationID
	FROM Staging.CardTransactionHolding h
	INNER JOIN Relational.Location n
		ON h.BrandCombinationID = n.ConsumerCombinationID
		AND h.LocationAddress = n.LocationAddress
	WHERE h.LocationID IS NULL

END
