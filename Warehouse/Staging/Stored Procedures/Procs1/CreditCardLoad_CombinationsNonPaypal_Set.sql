-- =============================================
-- Author:		JEA
-- Create date: 25/04/2018
-- Description:	sets non-paypal combinations in the credit card staging area
-- =============================================
create PROCEDURE [Staging].[CreditCardLoad_CombinationsNonPaypal_Set]
	
AS
	
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
FROM Staging.CreditCardLoad_InitialStage i WITH (TABLOCK)
CROSS APPLY (
	SELECT TOP(1) c.ConsumerCombinationID 
	FROM Relational.ConsumerCombination c 
	WHERE c.IsHighVariance = 0
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal
		AND i.MID = c.MID
		AND i.Narrative = c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
	ORDER BY c.ConsumerCombinationID DESC
) c
WHERE i.ConsumerCombinationID IS NULL;

UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
FROM Staging.CreditCardLoad_InitialStage i WITH (TABLOCK)
CROSS APPLY (
	SELECT TOP(1) c.ConsumerCombinationID 
	FROM Relational.ConsumerCombination c 
	WHERE c.IsHighVariance = 1
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal 
		AND i.MID = c.MID
		AND i.Narrative LIKE c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
	ORDER BY c.ConsumerCombinationID DESC
) c
WHERE i.ConsumerCombinationID IS NULL;
		

RETURN 0
