/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Clears, inserts and recreates the indexes on the table that holds
				the transaction file to be sent and outputs the number of rows
				that were inserted to be used to loop through in the SSIS package

				This is done this way rather than, simply counting from this table to 
				ensure the latest transactions MUST be pulled before uploading
				otherwise, there is a chance, that an old set of transactions could be
				uploaded with a new file date

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[FileExtraction_Transaction_Staging_Build](
	@FileDate DATE -- The date the file was produced that is to be staged
  , @FileType VARCHAR(10) -- The type of file to retrieve
  , @MaxLoopID INT OUTPUT -- The number of rows that were inserted
)
AS
BEGIN

	UPDATE Processing.Customers
	SET isNew = 0
	WHERE isNew = 1

	TRUNCATE TABLE Processing.FileExtraction_Transaction_Staging

	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'ucix_Processing_extract_trans'
				AND object_id = OBJECT_ID('Processing.FileExtraction_Transaction_Staging')
		)
		DROP INDEX ucix_Processing_extract_trans ON Processing.FileExtraction_Transaction_Staging


	INSERT INTO Processing.FileExtraction_Transaction_Staging
	(
		TransSequenceID
	  , RewardProxyUserID
	  , PerturbedDate
	  , RewardProxyMIDTupleID
	  , PerturbedAmount
	  , CurrencyCode
	  , CardholderPresentFlag
	  , CardType
	  , CardholderPostArea
	)
	 SELECT
		 TransSequenceID	   AS TransSequenceID
	   , ProxyUserID		   AS RewardProxyUserID
	   , PerturbedDate		   AS PerturbedDate
	   , ProxyMIDTupleID	   AS RewardProxyMIDTupleID
	   , PerturbedAmount	   AS PerturbedAmount
	   , CurrencyCode		   AS CurrencyCode
	   , CardholderPresentFlag AS CardholderPresentFlag
	   , CardType			   AS CardType
	   , CardholderPostcode	   AS CardholderPostArea
	 FROM Processing.TransactionPerturbation tl
	 WHERE FileDate = @FileDate
		 AND FileType = @FileType

	SET @MaxLoopID = @@rowcount

	CREATE UNIQUE CLUSTERED INDEX ucix_Processing_extract_trans ON Processing.FileExtraction_Transaction_Staging (LoopID)

	RETURN @MaxLoopID

END
