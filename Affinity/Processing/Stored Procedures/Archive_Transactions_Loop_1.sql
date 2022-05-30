
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Archives transaction from the daily loading table to the historical
				transaction table
------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Archive_Transactions_Loop]
AS
BEGIN

	SET XACT_ABORT ON

	----------------------------------------------------------------------
	-- Get Latest file id that was processed last
		-- if this is the first time running then the fileid will be null because the
		-- table is emptied after a successful archiving

		-- if the process fails part way, it will keep a log of the last fileid it used and
		-- can be simply re-run
	----------------------------------------------------------------------
	DECLARE @Rew_FileID INT = (SELECT MAX(REW_FileID) FROM Processing.Archive_FileIDs)	
	DECLARE @C INT 
	DECLARE @StartTime DATETIME2 = GETDATE()

	--SELECT @C = COUNT(DISTINCT REW_FileID) 
	--FROM processing.TransactionPerturbation 
	--WHERE Rew_FileID >= ISNULL(@Rew_FileID, -1000)

	WHILE 1=1
	BEGIN


			----------------------------------------------------------------------
			-- Get FileID to use
			----------------------------------------------------------------------

			-- If this is the first run, set to -1
			IF @Rew_FileID IS NULL
			BEGIN
				SET @Rew_FileID = -1
			END
			ELSE -- otherwise, set the fileid to be the next fileid after the last completed
			BEGIN
				SELECT @Rew_FileID = MIN(Rew_FileID)
				FROM Affinity.Processing.TransactionPerturbation
				WHERE REW_FileID > @Rew_FileID
			END

			-- Means there are no more fileids available to move
			IF @Rew_FileID IS NULL
				BREAK

			--DECLARE @Msg VARCHAR(MAX) = CONCAT('Remaining: ', @C)
			--RAISERROR (@Msg, 0, 1) WITH NOWAIT

		BEGIN TRANSACTION
			----------------------------------------------------------------------
			-- Perform Insert
			----------------------------------------------------------------------
			INSERT INTO dbo.Transactions (
				TransSequenceID, ProxyUserID, PerturbedDate, ProxyMIDTupleID, PerturbedAmount,
				CurrencyCode, CardholderPresentFlag, CardType, CardholderPostcode, REW_TransSequenceID_INT,
				REW_FanID, REW_SourceUID, REW_TranDate, REW_ConsumerCombinationID, REW_Amount, REW_Variance,
				REW_RandomNumber, REW_FileID, REW_RowNum, REW_Prefix, REW_CardholderPresentData,
				REW_CardholderPostcode, FileType, FileDate, CreatedDateTime)
			SELECT 
				TransSequenceID, ProxyUserID, PerturbedDate, ProxyMIDTupleID, PerturbedAmount,
				CurrencyCode, CardholderPresentFlag, CardType, CardholderPostcode, REW_TransSequenceID_INT,
				REW_FanID, REW_SourceUID, REW_TranDate, REW_ConsumerCombinationID, REW_Amount, REW_Variance,
				REW_RandomNumber, REW_FileID, REW_RowNum, REW_Prefix, REW_CardholderPresentData,
				REW_CardholderPostcode, FileType, FileDate, CreatedDateTime
			FROM [Affinity].Processing.[TransactionPerturbation] d -- 477,976,434
			WHERE d.REW_FileID = @Rew_FileID


			----------------------------------------------------------------------
			-- Store completed FileID so this process can be resumed
			----------------------------------------------------------------------
			INSERT INTO Processing.Archive_FileIDs
			SELECT @Rew_FileID	
		
		COMMIT TRANSACTION

		SET @C -=1

		IF DATEDIFF(HOUR, @StartTime, GETDATE()) >= 6
			BREAK

	END

	----------------------------------------------------------------------
	-- Once all rows have been moved, clear down tables
	----------------------------------------------------------------------
	--BEGIN TRANSACTION

	--	TRUNCATE TABLE Processing.Archive_FileIDs
	--	TRUNCATE TABLE Processing.TransactionPerturbation

	--COMMIT TRANSACTION

END




