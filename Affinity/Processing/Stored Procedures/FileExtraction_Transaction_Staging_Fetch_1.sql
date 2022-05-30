/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Fetches the set of rows from the transaction file based on
				how big the batch is and the batch required

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[FileExtraction_Transaction_Staging_Fetch](
	@LoopID INT -- The row number to pull from
  , @BatchSize INT -- the number of rows to pull
)

AS
BEGIN

	DECLARE @EndLoopID INT = @LoopID + @BatchSize

	SELECT
		TransSequenceID
	  , RewardProxyUserID
	  , PerturbedDate
	  , RewardProxyMIDTupleID
	  , PerturbedAmount
	  , CurrencyCode
	  , CardholderPresentFlag
	  , CardType
	  , CardholderPostArea
	FROM Processing.FileExtraction_Transaction_Staging fets
	WHERE fets.LoopID >= @LoopID AND fets.LoopID < @EndLoopID

	RETURN @@rowcount

END
