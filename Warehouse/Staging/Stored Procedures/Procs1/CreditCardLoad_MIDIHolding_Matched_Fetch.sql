-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Staging.CreditCardLoad_MIDIHolding_Matched_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT FileID
		, RowNum
		, OriginatorReference
		, LocationCountry
		, MID
		, Narrative
		, CardholderPresentMC
		, Amount
		, TranDate
		, ConsumerCombinationID
		, SecondaryCombinationID
		, RequiresSecondaryID
		, MCCID
		, LocationID
		, CINID
		, PaymentTypeID
		, FanID
	FROM Staging.CreditCardLoad_MIDIHolding
	WHERE ConsumerCombinationID IS NOT NULL

END

GO
GRANT EXECUTE
    ON OBJECT::[Staging].[CreditCardLoad_MIDIHolding_Matched_Fetch] TO [gas]
    AS [dbo];

