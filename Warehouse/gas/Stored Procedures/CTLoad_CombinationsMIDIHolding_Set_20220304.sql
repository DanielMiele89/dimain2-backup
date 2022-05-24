-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_CombinationsMIDIHolding_Set_20220304]
		WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @PaypalCount INT, @RowsAffected INT

	--update non-high variance non-paypal combinations
    UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_MIDIHolding i
	CROSS APPLY ( -- non-deterministic UPDATE
		SELECT TOP(1) c.ConsumerCombinationID 
		FROM Relational.ConsumerCombination c 
		WHERE c.IsHighVariance = 0
			AND c.PaymentGatewayStatusID != 1 -- not default Paypal
			AND i.MID = c.MID
			AND i.Narrative = c.Narrative
			AND i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorID = c.OriginatorID
		ORDER BY c.ConsumerCombinationID DESC
	) c
	WHERE i.ConsumerCombinationID IS NULL


	UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM staging.creditcardload_midiholding i
	CROSS APPLY ( -- non-deterministic UPDATE
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
	WHERE i.ConsumerCombinationID IS NULL

	--update high variance non-paypal combinations
	UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_MIDIHolding i
	CROSS APPLY ( -- non-deterministic UPDATE
		SELECT TOP(1) c.ConsumerCombinationID 
		FROM Relational.ConsumerCombination c 
		WHERE c.IsHighVariance = 1
			AND c.PaymentGatewayStatusID != 1 -- not default Paypal
			AND i.MID = c.MID
			AND i.Narrative LIKE c.Narrative
			AND i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorID = c.OriginatorID	
		ORDER BY c.ConsumerCombinationID DESC
	) c
	WHERE i.ConsumerCombinationID IS NULL

	UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM staging.creditcardload_midiholding i
	CROSS APPLY ( -- non-deterministic UPDATE
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
	WHERE i.ConsumerCombinationID IS NULL

	--	Fetch all generic PayPal CCs
	IF OBJECT_ID('tempdb..#PaypalCombosNonDefault') IS NOT NULL DROP TABLE #PaypalCombosNonDefault
	SELECT	MAX(ConsumerCombinationID) AS ConsumerCombinationID
		,	LocationCountry
		,	MCCID
		,	OriginatorID
		,	MID
		,	Narrative
	INTO #PaypalCombosNonDefault
	FROM [Relational].[ConsumerCombination]
	WHERE PaymentGatewayStatusID = 1
	GROUP BY LocationCountry
		,	MCCID
		,	OriginatorID
		,	MID
		,	Narrative

	CREATE CLUSTERED INDEX IX_TMP_PaypalConsCom ON #PaypalCombosNonDefault (LocationCountry, MCCID, OriginatorID)


	--	Fetch all new PayPal MIDs that don't have an existing CC but have < 5 trans
	IF OBJECT_ID('tempdb..#PaypalMIDNew') IS NOT NULL DROP TABLE #PaypalMIDNew
	SELECT MID, TranCount = COUNT(*)
	INTO #PaypalMIDNew
	FROM [Staging].[CTLoad_MIDIHolding]
	WHERE Narrative LIKE 'PAYPAL%'
	GROUP BY MID
	HAVING COUNT(*) < 10

	CREATE CLUSTERED INDEX cx_Stuff ON #PaypalMIDNew (MID)
	
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
				
	UPDATE m SET 
		ConsumerCombinationID = p.ConsumerCombinationID,
		RequiresSecondaryID = 1
	FROM staging.creditcardload_midiholding M
	CROSS APPLY ( -- non-deterministic UPDATE
		SELECT TOP(1) p.ConsumerCombinationID 
		FROM #PaypalCombosNonDefault P
		WHERE M.Narrative LIKE 'PAYPAL%'
			AND M.LocationCountry = P.LocationCountry
			AND M.MCCID = P.MCCID
			AND M.OriginatorReference = P.OriginatorID
		ORDER BY p.ConsumerCombinationID DESC
	) p
	WHERE M.ConsumerCombinationID IS NULL
	AND EXISTS (SELECT 1
				FROM #PaypalMIDNew pmn
				WHERE M.MID = pmn.MID)
	AND NOT EXISTS (SELECT 1
					FROM [staging].[BrandMatch] bm
					WHERE M.Narrative LIKE bm.Narrative
					AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal


	UPDATE m
		SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_MIDIHolding m
	CROSS APPLY ( -- non-deterministic UPDATE
		SELECT TOP(1) p.PaymentGatewayID
		FROM Relational.PaymentGatewaySecondaryDetail p 
		WHERE m.ConsumerCombinationID = p.ConsumerCombinationID
			AND m.MID = p.MID
			AND m.Narrative = p.Narrative
		ORDER BY p.PaymentGatewayID DESC
	) p
	WHERE m.SecondaryCombinationID IS NULL
		AND m.RequiresSecondaryID = 1

	UPDATE m
		SET SecondaryCombinationID = p.PaymentGatewayID
	FROM staging.creditcardload_midiholding m
	CROSS APPLY ( -- non-deterministic UPDATE
		SELECT TOP(1) p.PaymentGatewayID
		FROM Relational.PaymentGatewaySecondaryDetail p 
		WHERE m.ConsumerCombinationID = p.ConsumerCombinationID
			AND m.MID = p.MID
			AND m.Narrative = p.Narrative
		ORDER BY p.PaymentGatewayID DESC
	) p
	WHERE m.SecondaryCombinationID IS NULL
		AND m.RequiresSecondaryID = 1



	INSERT INTO Relational.PaymentGatewaySecondaryDetail
		(ConsumerCombinationID, MID, Narrative)	
	SELECT DISTINCT	-- dupe avoidance CJM
		ConsumerCombinationID, MID, Narrative
	FROM (
		SELECT ConsumerCombinationID, MID, Narrative
		FROM Staging.CTLoad_MIDIHolding mh
		WHERE RequiresSecondaryID = 1
		AND SecondaryCombinationID IS NULL
		UNION ALL
		SELECT ConsumerCombinationID, MID, Narrative
		FROM staging.creditcardload_midiholding mh
		WHERE RequiresSecondaryID = 1
		AND SecondaryCombinationID IS NULL
	) d
	WHERE NOT EXISTS (
		SELECT 1
		FROM Relational.PaymentGatewaySecondaryDetail pg
		WHERE d.ConsumerCombinationID = pg.ConsumerCombinationID)
	SET @RowsAffected = @@ROWCOUNT


	IF @RowsAffected > 0 BEGIN

		UPDATE Staging.CTLoad_MIDIHolding
		SET SecondaryCombinationID = p.PaymentGatewayID
		FROM Staging.CTLoad_MIDIHolding m
		CROSS APPLY ( -- non-deterministic UPDATE
			SELECT TOP(1) p.PaymentGatewayID 
			FROM Relational.PaymentGatewaySecondaryDetail p 
			WHERE m.ConsumerCombinationID = p.ConsumerCombinationID
			AND m.MID = p.MID
			AND m.Narrative = p.Narrative		
		) p
		WHERE m.SecondaryCombinationID IS NULL
			AND m.RequiresSecondaryID = 1

		UPDATE m
		SET SecondaryCombinationID = p.PaymentGatewayID
		FROM staging.creditcardload_midiholding m
		CROSS APPLY ( -- non-deterministic UPDATE
			SELECT TOP(1) p.PaymentGatewayID 
			FROM Relational.PaymentGatewaySecondaryDetail p 
			WHERE m.ConsumerCombinationID = p.ConsumerCombinationID
			AND m.MID = p.MID
			AND m.Narrative = p.Narrative		
		) p
		WHERE m.SecondaryCombinationID IS NULL
			AND m.RequiresSecondaryID = 1

	END

END