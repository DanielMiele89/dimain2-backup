-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_CombinationsPaypal_Set_20211210]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	--	Fetch all generic PayPal CCs
	IF OBJECT_ID('tempdb..#PaypalCombosNonDefault') IS NOT NULL DROP TABLE #PaypalCombosNonDefault
	CREATE TABLE #PaypalCombosNonDefault (	ConsumerCombinationID INT
										,	LocationCountry VARCHAR(3) NOT NULL
										,	MCCID SMALLINT NOT NULL
										,	OriginatorID VARCHAR(11) NOT NULL
										,	MID VARCHAR(50) NOT NULL
										,	Narrative VARCHAR(50))

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

	CREATE CLUSTERED INDEX CIX_LocationOrigMCC ON #PaypalCombosNonDefault (LocationCountry, MCCID, OriginatorID, ConsumerCombinationID)

	--	Fetch all new PayPal MIDs that don't have an existing CC but have < 5 trans
	IF OBJECT_ID('tempdb..#PaypalMIDNew') IS NOT NULL DROP TABLE #PaypalMIDNew
	CREATE TABLE #PaypalMIDNew (MID VARCHAR(50)
							,	TranCount INT NOT NULL)

	INSERT INTO #PaypalMIDNew (	MID
							,	TranCount)
	SELECT	MID
		,	COUNT(*)
	FROM [Staging].[CTLoad_InitialStage]
	WHERE Narrative LIKE 'PAYPAL%'
	GROUP BY MID
	HAVING COUNT(*) < 10

	CREATE INDEX CIX_MID ON #PaypalMIDNew (MID)


	--	Assign generic PayPal CC to PayPal trans with <10 trans per MID

	UPDATE [Staging].[CTLoad_InitialStage]
	SET	ConsumerCombinationID = c.ConsumerCombinationID
	,	RequiresSecondaryID = 1
	FROM [Staging].[CTLoad_InitialStage] i
	INNER JOIN #PaypalCombosNonDefault c
		ON i.Narrative LIKE 'PAYPAL%'
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorID = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
	AND EXISTS (SELECT 1
				FROM #PaypalMIDNew pmn
				WHERE i.MID = pmn.MID)
	AND NOT EXISTS (SELECT 1
					FROM [staging].[BrandMatch] bm
					WHERE i.Narrative LIKE bm.Narrative
					AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal

	--	If there are PayPal trans with <10 trans per MID remaining that don't have a CC, breate one & assign it
	DECLARE @ComboRequiredCount INT

	SELECT @ComboRequiredCount = COUNT(1)
	FROM [Staging].[CTLoad_InitialStage] i
	WHERE ConsumerCombinationID IS NULL
	AND Narrative LIKE 'PAYPAL%'
	AND EXISTS (SELECT 1
				FROM #PaypalMIDNew pmn
				WHERE i.MID = pmn.MID)
	AND NOT EXISTS (SELECT 1
					FROM [staging].[BrandMatch] bm
					WHERE i.Narrative LIKE bm.Narrative
					AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal

	SELECT @ComboRequiredCount

	IF @ComboRequiredCount > 0
	BEGIN

		ALTER INDEX [IX_NCL_Relational_ConsumerCombination_Matching] ON [Relational].[ConsumerCombination] DISABLE
		ALTER INDEX [IX_Relational_ConsumerCombination] ON [Relational].[ConsumerCombination] DISABLE
		
		INSERT INTO [Relational].[ConsumerCombination] (BrandMIDID
													,	BrandID
													,	MID
													,	Narrative
													,	LocationCountry
													,	MCCID
													,	OriginatorID
													,	IsHighVariance
													,	IsUKSpend
													,	PaymentGatewayStatusID)
		SELECT	DISTINCT
				142652 AS BrandMIDID
			,	943 AS BrandID
			,	'%' AS MID
			,	'PAYPAL%' AS Narrative
			,	LocationCountry
			,	MCCID
			,	OriginatorID
			,	1 AS IsHighVariance
			,	CASE
					WHEN LocationCountry = 'GB' THEN 1
					ELSE 0
				END AS IsUKSpend
			,	1 AS PaymentGatewayStatusID
		FROM [Staging].[CTLoad_InitialStage] i
		WHERE ConsumerCombinationID IS NULL
		AND Narrative LIKE 'PAYPAL%'
		AND EXISTS (SELECT 1
					FROM #PaypalMIDNew pmn
					WHERE i.MID = pmn.MID)
		AND NOT EXISTS (SELECT 1
						FROM [staging].[BrandMatch] bm
						WHERE i.Narrative LIKE bm.Narrative
						AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal
		
		ALTER INDEX [IX_NCL_Relational_ConsumerCombination_Matching] ON [Relational].[ConsumerCombination] REBUILD
		ALTER INDEX [IX_Relational_ConsumerCombination] ON [Relational].[ConsumerCombination] REBUILD

		INSERT INTO #PaypalCombosNonDefault (	ConsumerCombinationID
											,	LocationCountry
											,	MCCID
											,	OriginatorID
											,	MID
											,	Narrative)

		SELECT	ConsumerCombinationID
			,	LocationCountry
			,	MCCID
			,	OriginatorID
			,	MID
			,	Narrative
		FROM [Relational].[ConsumerCombination] cc
		WHERE PaymentGatewayStatusID = 1
		AND NOT EXISTS (SELECT 1
						FROM #PaypalCombosNonDefault pnc
						WHERE cc.LocationCountry = pnc.LocationCountry
						AND cc.MCCID = pnc.MCCID
						AND cc.OriginatorID = pnc.OriginatorID)


		UPDATE [Staging].[CTLoad_InitialStage]
		SET	ConsumerCombinationID = c.ConsumerCombinationID
		,	RequiresSecondaryID = 1
		FROM [Staging].[CTLoad_InitialStage] i
		INNER JOIN #PaypalCombosNonDefault c
			ON i.Narrative LIKE 'PAYPAL%'
			AND i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorID = c.OriginatorID
		WHERE i.ConsumerCombinationID IS NULL
		AND EXISTS (SELECT 1
					FROM #PaypalMIDNew pmn
					WHERE i.MID = pmn.MID)
		AND NOT EXISTS (SELECT 1
						FROM [staging].[BrandMatch] bm
						WHERE i.Narrative LIKE bm.Narrative
						AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal

	END

END