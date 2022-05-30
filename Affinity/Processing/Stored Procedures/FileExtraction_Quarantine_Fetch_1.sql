/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Fetch the set of rows for the Quarantine file based on the 
				date the file was produced

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[FileExtraction_Quarantine_Fetch] (
	@FileDate DATE -- The date that the file was produced
)
AS
BEGIN


	SELECT
		tpml.TransSequenceID
	  , tpml.ProxyUserID		 AS RewardProxyUserID
	  , tpml.PerturbedDate
	  , tpml.ProxyMID			 AS RewardProxyMID
	  , tpml.MCC				 AS MerchantCategoryCode
	  , tpml.MerchantDescriptor
	  , tpml.CountryCode
	  , tpml.LocationAddress	 AS MerchantLocation
	  , tpml.OriginatorID
	  , tpml.TempProxyMIDTupleID AS TemporaryProxyMIDTupleID
	  , tpml.PerturbedAmount
	  , tpml.CurrencyCode
	  , tpml.CardholderPresentFlag
	  , tpml.CardType
	  , tpml.CardholderPostcode	 AS CardholderPostArea
	FROM Processing.TransactionPerturbation_MIDI tpml
	WHERE tpml.FileDate = @FileDate

	RETURN @@rowcount

END
