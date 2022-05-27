-- =============================================
-- Author:		JEA
-- Create date: 25/04/2018
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_CombinationsPaypal_Set]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @RowsAffected INT


	SELECT DISTINCT 
		ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
	INTO #PaypalCombosNonDefault
	FROM Relational.ConsumerCombination
	WHERE PaymentGatewayStatusID = 1

	CREATE CLUSTERED INDEX IX_TMP_PaypalCombosNonDefault ON #PaypalCombosNonDefault (LocationCountry, MCCID, OriginatorID)


	SELECT MID, TranCount = COUNT(*)
	INTO #PaypalMIDNew
	FROM Staging.CTLoad_InitialStage
	WHERE Narrative LIKE 'PAYPAL%'
		AND ConsumerCombinationID IS NULL
	GROUP BY MID
	HAVING COUNT(*) >= 10

	CREATE UNIQUE CLUSTERED INDEX cx_Stuff ON #PaypalMIDNew (MID)


	UPDATE i SET 
		ConsumerCombinationID = c.ConsumerCombinationID,
		RequiresSecondaryID = 1
	FROM Staging.CreditCardLoad_InitialStage i WITH (TABLOCK)
	CROSS APPLY ( -- non-deterministic UPDATE
		SELECT TOP(1) c.ConsumerCombinationID 
		FROM #PaypalCombosNonDefault c 
		WHERE i.Narrative LIKE 'PAYPAL%'
			AND i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorReference = c.OriginatorID
		ORDER BY c.ConsumerCombinationID DESC
	) c
	WHERE i.ConsumerCombinationID IS NULL
	AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)



		
	INSERT INTO Relational.ConsumerCombination 
		(BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
	SELECT DISTINCT -- avoid dupes CJM
		142652, 943, '%', 'PAYPAL%', LocationCountry, MCCID, OriginatorReference, 1, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END, 1
	FROM Staging.CreditCardLoad_InitialStage i
	WHERE ConsumerCombinationID IS NULL
		AND Narrative LIKE 'PAYPAL%'
		AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)
	ORDER BY LocationCountry, MCCID, OriginatorReference, 1, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END
	SET @RowsAffected = @@ROWCOUNT
		

	IF @RowsAffected > 0 BEGIN

		UPDATE i SET 
			ConsumerCombinationID = c.ConsumerCombinationID,
			RequiresSecondaryID = 1
		FROM Staging.CreditCardLoad_InitialStage i WITH (TABLOCK)
		CROSS APPLY (
			SELECT TOP(1) c.ConsumerCombinationID
			FROM #PaypalCombosNonDefault c 
			WHERE i.Narrative LIKE 'PAYPAL%'
				AND i.LocationCountry = c.LocationCountry
				AND i.MCCID = c.MCCID
				AND i.OriginatorReference = c.OriginatorID
			ORDER BY c.ConsumerCombinationID DESC
		) c
		WHERE i.ConsumerCombinationID IS NULL
		AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)

	END

END

RETURN 0