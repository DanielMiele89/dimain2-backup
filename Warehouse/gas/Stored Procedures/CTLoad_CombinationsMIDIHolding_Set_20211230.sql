-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_CombinationsMIDIHolding_Set_20211230]
		WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @PaypalCount INT

	--update non-high variance non-paypal combinations
    UPDATE Staging.CTLoad_MIDIHolding
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_MIDIHolding i
	INNER JOIN Relational.ConsumerCombination c ON
		i.MID = c.MID
		AND i.Narrative = c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorID = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
		AND c.IsHighVariance = 0
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal

	UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM staging.creditcardload_midiholding i
	INNER JOIN Relational.ConsumerCombination c ON
		i.MID = c.MID
		AND i.Narrative = c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
		AND c.IsHighVariance = 0
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal

	--update high variance non-paypal combinations
	UPDATE Staging.CTLoad_MIDIHolding
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_MIDIHolding i
	INNER JOIN Relational.ConsumerCombination c ON
		i.MID = c.MID
		AND i.Narrative LIKE c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorID = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
		AND c.IsHighVariance = 1
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal

	UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM staging.creditcardload_midiholding i
	INNER JOIN Relational.ConsumerCombination c ON
		i.MID = c.MID
		AND i.Narrative LIKE c.Narrative
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
		AND c.IsHighVariance = 1
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal

	--	Fetch all generic PayPal CCs
	IF OBJECT_ID('tempdb..#PaypalCombosNonDefault') IS NOT NULL DROP TABLE #PaypalCombosNonDefault
	CREATE TABLE #PaypalCombosNonDefault (	ConsumerCombinationID INT PRIMARY KEY
										,	LocationCountry VARCHAR(3) NOT NULL
										,	MCCID SMALLINT NOT NULL
										,	OriginatorID VARCHAR(11) NOT NULL
										,	MID VARCHAR(50) NOT NULL
										,	Narrative VARCHAR(50) NOT NULL)

	INSERT INTO #PaypalCombosNonDefault (	ConsumerCombinationID
										,	LocationCountry
										,	MCCID
										,	OriginatorID
										,	MID
										,	Narrative)
	SELECT	MAX(ConsumerCombinationID) AS ConsumerCombinationID
		,	LocationCountry
		,	MCCID
		,	OriginatorID
		,	MID
		,	Narrative
	FROM [Relational].[ConsumerCombination]
	WHERE PaymentGatewayStatusID = 1
	GROUP BY LocationCountry
		,	MCCID
		,	OriginatorID
		,	MID
		,	Narrative

	CREATE INDEX IX_TMP_PaypalConsCom ON #PaypalCombosNonDefault(LocationCountry, MCCID, OriginatorID)

	--	Fetch all new PayPal MIDs that don't have an existing CC but have < 5 trans
	IF OBJECT_ID('tempdb..#PaypalMIDNew') IS NOT NULL DROP TABLE #PaypalMIDNew
	CREATE TABLE #PaypalMIDNew (MID VARCHAR(50)
							,	TranCount INT NOT NULL)

	INSERT INTO #PaypalMIDNew (	MID
							,	TranCount)
	SELECT	MID
		,	COUNT(*)
	FROM [Staging].[CTLoad_MIDIHolding]
	WHERE Narrative LIKE 'PAYPAL%'
	GROUP BY MID
	HAVING COUNT(*) < 10

	CREATE INDEX IX_TMP_PaypalCombosNonDefault ON #PaypalCombosNonDefault(LocationCountry, MCCID, OriginatorID)
	
	--	Assign generic PayPal CC to PayPal trans with <10 trans per MID
	UPDATE m
	SET ConsumerCombinationID = p.ConsumerCombinationID
		, RequiresSecondaryID = 1
	FROM Staging.CTLoad_MIDIHolding M
	INNER JOIN #PaypalCombosNonDefault P
		ON M.Narrative LIKE 'PAYPAL%'
		AND M.LocationCountry = P.LocationCountry
		AND M.MCCID = P.MCCID
		AND M.OriginatorID = P.OriginatorID
	WHERE M.ConsumerCombinationID IS NULL
	AND EXISTS (SELECT 1
				FROM #PaypalMIDNew pmn
				WHERE M.MID = pmn.MID)
	AND NOT EXISTS (SELECT 1
					FROM [staging].[BrandMatch] bm
					WHERE M.Narrative LIKE bm.Narrative
					AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal

	UPDATE m
	SET ConsumerCombinationID = p.ConsumerCombinationID
		, RequiresSecondaryID = 1
	FROM staging.creditcardload_midiholding M
	INNER JOIN #PaypalCombosNonDefault P
		ON M.Narrative LIKE 'PAYPAL%'
		AND M.LocationCountry = P.LocationCountry
		AND M.MCCID = P.MCCID
		AND M.OriginatorReference = P.OriginatorID
	WHERE M.ConsumerCombinationID IS NULL
	AND EXISTS (SELECT 1
				FROM #PaypalMIDNew pmn
				WHERE M.MID = pmn.MID)
	AND NOT EXISTS (SELECT 1
					FROM [staging].[BrandMatch] bm
					WHERE M.Narrative LIKE bm.Narrative
					AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal

	UPDATE Staging.CTLoad_MIDIHolding
	SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_MIDIHolding m
	INNER JOIN Relational.PaymentGatewaySecondaryDetail p ON m.ConsumerCombinationID = p.ConsumerCombinationID
		AND m.MID = p.MID
		AND m.Narrative = p.Narrative
	WHERE m.SecondaryCombinationID IS NULL
	AND m.RequiresSecondaryID = 1

	UPDATE m
	SET SecondaryCombinationID = p.PaymentGatewayID
	FROM staging.creditcardload_midiholding m
	INNER JOIN Relational.PaymentGatewaySecondaryDetail p ON m.ConsumerCombinationID = p.ConsumerCombinationID
		AND m.MID = p.MID
		AND m.Narrative = p.Narrative
	WHERE m.SecondaryCombinationID IS NULL
	AND m.RequiresSecondaryID = 1

	SELECT @PaypalCount = COUNT(1)
	FROM Staging.CTLoad_MIDIHolding
	WHERE RequiresSecondaryID = 1
	AND SecondaryCombinationID IS NULL

	IF @PaypalCount = 0
	BEGIN
		SELECT @PaypalCount = COUNT(1)
		FROM staging.creditcardload_midiholding
		WHERE RequiresSecondaryID = 1
		AND SecondaryCombinationID IS NULL
	END

	IF @PaypalCount > 0
	BEGIN
		--ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail DISABLE

		INSERT INTO Relational.PaymentGatewaySecondaryDetail(ConsumerCombinationID, MID, Narrative)
		
		SELECT ConsumerCombinationID, MID, Narrative
		FROM Staging.CTLoad_MIDIHolding mh
		WHERE RequiresSecondaryID = 1
		AND SecondaryCombinationID IS NULL
		AND NOT EXISTS (SELECT 1
						FROM Relational.PaymentGatewaySecondaryDetail pg
						WHERE mh.ConsumerCombinationID = pg.ConsumerCombinationID)

		UNION

		SELECT ConsumerCombinationID, MID, Narrative
		FROM staging.creditcardload_midiholding mh
		WHERE RequiresSecondaryID = 1
		AND SecondaryCombinationID IS NULL
		AND NOT EXISTS (SELECT 1
						FROM Relational.PaymentGatewaySecondaryDetail pg
						WHERE mh.ConsumerCombinationID = pg.ConsumerCombinationID)

		--ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212 / 20201701 added fillfactor to index

		UPDATE Staging.CTLoad_MIDIHolding
		SET SecondaryCombinationID = p.PaymentGatewayID
		FROM Staging.CTLoad_MIDIHolding m
		INNER JOIN Relational.PaymentGatewaySecondaryDetail p ON m.ConsumerCombinationID = p.ConsumerCombinationID
			AND m.MID = p.MID
			AND m.Narrative = p.Narrative
		WHERE m.SecondaryCombinationID IS NULL
		AND m.RequiresSecondaryID = 1

		UPDATE m
		SET SecondaryCombinationID = p.PaymentGatewayID
		FROM staging.creditcardload_midiholding m
		INNER JOIN Relational.PaymentGatewaySecondaryDetail p ON m.ConsumerCombinationID = p.ConsumerCombinationID
			AND m.MID = p.MID
			AND m.Narrative = p.Narrative
		WHERE m.SecondaryCombinationID IS NULL
		AND m.RequiresSecondaryID = 1

	END

END