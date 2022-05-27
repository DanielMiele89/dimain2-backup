-- =============================================
-- Author:		JEA
-- Create date: 25/04/2018
-- Description:	sets non-paypal combinations in the credit card staging area
-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_CombinationsNonPaypal_Set_20211230]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CreditCardLoad_InitialStage i
	INNER JOIN Relational.ConsumerCombination c ON
		i.MID = c.MID
		AND i.Narrative = c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
		AND c.IsHighVariance = 0
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal

	UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CreditCardLoad_InitialStage i
	INNER JOIN Relational.ConsumerCombination c ON
		i.MID = c.MID
		AND i.Narrative LIKE c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
		AND c.IsHighVariance = 1
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal

END
