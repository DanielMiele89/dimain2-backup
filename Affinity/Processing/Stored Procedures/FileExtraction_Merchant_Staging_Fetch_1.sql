/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Fetch the set of rows for the merchant file based on how big
				each batch should be and the batch that is required

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[FileExtraction_Merchant_Staging_Fetch](
	@LoopID INT -- The rownumber to start the pull from
  , @BatchSize INT -- the number of rows to pull
)

AS
BEGIN

	DECLARE @EndLoopID INT = @LoopID + @BatchSize

	SELECT
		fets.RewardProxyMIDTupleID
	  , fets.MCCCode
	  , fets.RewardProxyMID
	  , fets.MerchantDescriptor
	  , fets.MerchantPostcode
	  , fets.MerchantName
	  , fets.MerchantLocation
	  , fets.CountryCode
	FROM Processing.FileExtraction_Merchant_Staging fets
	WHERE fets.LoopID >= @LoopID AND fets.LoopID < @EndLoopID

	RETURN @@rowcount

END
