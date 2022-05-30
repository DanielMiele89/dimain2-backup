/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Archives transaction from the daily loading table to the historical
				transaction table

------------------------------------------------------------------------------
Known Issues and Considerations

------------------------------------------------------------------------------
Modification History

2021-07-07 Hayden Reid
	- Changed to not be a loop now that most rows have been moved, can attack the problem aggresively
		-- Older loop package in Processing.Archive_Transactions_Loop -- check before running, may not necessarily be updated

******************************************************************************/
CREATE PROCEDURE [Processing].[Archive_Transactions]
AS
BEGIN

	SET XACT_ABORT ON

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

			TRUNCATE TABLE Processing.TransactionPerturbation

		COMMIT TRANSACTION

END