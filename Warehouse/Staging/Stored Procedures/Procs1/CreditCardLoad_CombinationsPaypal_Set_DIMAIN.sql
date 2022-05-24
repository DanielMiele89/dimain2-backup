-- =============================================
-- Author:		JEA
-- Create date: 25/04/2018
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_CombinationsPaypal_Set_DIMAIN]
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
	
	DECLARE @RowsAffected INT


		
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