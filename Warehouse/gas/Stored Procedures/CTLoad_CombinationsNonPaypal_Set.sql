-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_CombinationsNonPaypal_Set]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_InitialStage i WITH (TABLOCK)
	CROSS APPLY ( -- non-deterministic update
		SELECT TOP 1 * 
		FROM Relational.ConsumerCombination c 
		WHERE c.IsHighVariance = 0
			AND c.PaymentGatewayStatusID != 1 -- not default Paypal
			AND i.MID = c.MID
			AND i.Narrative = c.Narrative
			AND i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorID = c.OriginatorID	
		ORDER BY ConsumerCombinationID DESC
	) c
	WHERE i.ConsumerCombinationID IS NULL


	UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_InitialStage i WITH (TABLOCK)
	CROSS APPLY ( -- non-deterministic update
		SELECT TOP(1) ConsumerCombinationID
		FROM Relational.ConsumerCombination c 
		WHERE c.IsHighVariance = 1
			AND c.PaymentGatewayStatusID != 1 -- not default Paypal
			AND i.MID = c.MID
			AND i.Narrative LIKE c.Narrative -- ##
			AND i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorID = c.OriginatorID
		ORDER BY ConsumerCombinationID DESC
	) c
	WHERE i.ConsumerCombinationID IS NULL


END
