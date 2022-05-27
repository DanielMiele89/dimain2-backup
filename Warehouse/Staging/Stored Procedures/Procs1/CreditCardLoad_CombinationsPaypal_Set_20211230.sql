-- =============================================
-- Author:		JEA
-- Create date: 25/04/2018
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_CombinationsPaypal_Set_20211230]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	CREATE TABLE #PaypalCombosNonDefault(ConsumerCombinationID INT PRIMARY KEY
		, LocationCountry VARCHAR(3) NOT NULL
		, MCCID SMALLINT NOT NULL
		, OriginatorID VARCHAR(11) NOT NULL)

	CREATE TABLE #PaypalMIDNew(MID VARCHAR(50) PRIMARY KEY, TranCount INT NOT NULL)

	INSERT INTO #PaypalCombosNonDefault(ConsumerCombinationID, LocationCountry, MCCID, OriginatorID)
	SELECT ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
	FROM Relational.ConsumerCombination
	WHERE PaymentGatewayStatusID = 1

	CREATE INDEX IX_TMP_PaypalCombosNonDefault ON #PaypalCombosNonDefault(LocationCountry, MCCID, OriginatorID)

	INSERT INTO #PaypalMIDNew(MID, TranCount)
	SELECT MID, COUNT(*)
	FROM Staging.CTLoad_InitialStage
	WHERE Narrative LIKE 'PAYPAL%'
	AND ConsumerCombinationID IS NULL
	GROUP BY MID
	HAVING COUNT(*) >= 10

	UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
		, RequiresSecondaryID = 1
	FROM Staging.CreditCardLoad_InitialStage i
	INNER JOIN #PaypalCombosNonDefault c ON
		i.Narrative LIKE 'PAYPAL%'
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
	LEFT OUTER JOIN #PaypalMIDNew pn ON i.MID = pn.MID
	WHERE i.ConsumerCombinationID IS NULL
	AND pn.MID IS NULL

	DECLARE @ComboRequiredCount INT

	SELECT @ComboRequiredCount = COUNT(1)
	FROM Staging.CreditCardLoad_InitialStage i
	LEFT OUTER JOIN #PaypalMIDNew pn ON i.MID = pn.MID
	WHERE ConsumerCombinationID IS NULL
	AND Narrative LIKE 'PAYPAL%'
	AND pn.MID IS NULL

	IF @ComboRequiredCount > 0
	BEGIN

		EXEC gas.CTLoad_ConsumerCombinationIndexes_Disable
		
		INSERT INTO Relational.ConsumerCombination(BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
		SELECT 142652, 943, '%', 'PAYPAL%', LocationCountry, MCCID, OriginatorReference, 1, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END, 1
		FROM Staging.CreditCardLoad_InitialStage i
		LEFT OUTER JOIN #PaypalMIDNew pn ON i.MID = pn.MID
		WHERE ConsumerCombinationID IS NULL
			AND Narrative LIKE 'PAYPAL%'
			AND pn.MID IS NULL
		
		EXEC gas.CTLoad_ConsumerCombinationIndexes_Rebuild

		UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
			, RequiresSecondaryID = 1
		FROM Staging.CreditCardLoad_InitialStage i
		INNER JOIN #PaypalCombosNonDefault c ON
			i.Narrative LIKE 'PAYPAL%'
			AND i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorReference = c.OriginatorID
		LEFT OUTER JOIN #PaypalMIDNew pn ON i.MID = pn.MID
		WHERE i.ConsumerCombinationID IS NULL
		AND pn.MID IS NULL

	END

END