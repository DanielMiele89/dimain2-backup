-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_CombinationsNonPaypal_Set_20211210]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    UPDATE Staging.CTLoad_InitialStage
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_InitialStage i
	INNER JOIN Relational.ConsumerCombination c ON
		i.MID = c.MID
		AND i.Narrative = c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorID = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
		AND c.IsHighVariance = 0
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal

	UPDATE Staging.CTLoad_InitialStage
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_InitialStage i
	INNER JOIN Relational.ConsumerCombination c ON
		i.MID = c.MID
		AND i.Narrative LIKE c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorID = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
		AND c.IsHighVariance = 1
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal

END