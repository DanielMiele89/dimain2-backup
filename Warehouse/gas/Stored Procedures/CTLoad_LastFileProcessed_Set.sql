-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Persists the ID of the last file processed
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_LastFileProcessed_Set]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @FileID INT

	SELECT @FileID = MAX(FileID) FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)

	IF @FileID IS NULL
	BEGIN
		SELECT @FileID = MAX(FileID) FROM Relational.ConsumerTransaction WITH (NOLOCK)
	END

	UPDATE Staging.CTLoad_LastFileProcessed SET FileID = @FileID
		, ProcessDate = GETDATE()
	WHERE FileID < @FileID

	DECLARE @LatestFile INT

	SELECT @LatestFile = MAX(FileID)
	FROM (	SELECT FileID = MAX(FileID)
			FROM Relational.ConsumerTransaction_CreditCard WITH (NOLOCK)
			UNION ALL
			SELECT FileID = MAX(FileID)
			FROM Relational.ConsumerTransaction_CreditCardHolding WITH (NOLOCK)
			UNION ALL
			SELECT FileID = MAX(FileID)
			FROM Staging.CreditCardLoad_MIDIHolding WITH (NOLOCK)) ct

	IF @LatestFile IS NOT NULL
	BEGIN
		UPDATE Staging.CreditCardLoad_LastFileProcessed SET FileID = @LatestFile
	END

	-- Extra insert for AWS upload

	INSERT INTO AWSFile.ConsumerTransaction_CreditCardForFile
	SELECT FileID
		 , RowNum
		 , ConsumerCombinationID
		 , CardholderPresentData
		 , TranDate
		 , CINID
		 , Amount
		 , IsOnline
		 , LocationID
		 , FanID
	FROM Relational.ConsumerTransaction_CreditCardHolding h
	WHERE NOT EXISTS (
		SELECT NULL FROM AWSFile.ConsumerTransaction_CreditCardForFile x
		WHERE
		h.FileID = x.FileID
		AND h.RowNum = x.RowNum
	);

END