-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_CombinationsPaypal_Set_DIMAIN]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	--	Fetch all generic PayPal CCs
	IF OBJECT_ID('tempdb..#PaypalCombosNonDefault') IS NOT NULL DROP TABLE #PaypalCombosNonDefault
	SELECT	MAX(ConsumerCombinationID) AS ConsumerCombinationID
		,	LocationCountry	-- used for join to CTLoad_InitialStage
		,	MCCID			-- used for join to CTLoad_InitialStage
		,	OriginatorID	-- used for join to CTLoad_InitialStage
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

	CREATE CLUSTERED INDEX CIX_LocationOrigMCC ON #PaypalCombosNonDefault (LocationCountry, MCCID, OriginatorID, ConsumerCombinationID)

	--	Fetch all new PayPal MIDs that don't have an existing CC but have < 5 trans
	IF OBJECT_ID('tempdb..#PaypalMIDNew') IS NOT NULL DROP TABLE #PaypalMIDNew
	SELECT	MID, TranCount = COUNT(*)
	INTO #PaypalMIDNew
	FROM [Staging].[CTLoad_InitialStage] WITH (TABLOCK)
	WHERE Narrative LIKE 'PAYPAL%'
	GROUP BY MID
	HAVING COUNT(*) < 10

	CREATE CLUSTERED INDEX CIX_MID ON #PaypalMIDNew (MID)


	--	Assign generic PayPal CC to PayPal trans with <10 trans per MID

	UPDATE i SET	
		ConsumerCombinationID = c.ConsumerCombinationID,	
		RequiresSecondaryID = 1
	FROM [Staging].[CTLoad_InitialStage] i WITH (TABLOCK)
	CROSS APPLY ( -- non-deterministic UPDATE
		SELECT TOP(1) ConsumerCombinationID
		FROM #PaypalCombosNonDefault c
		WHERE i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorID = c.OriginatorID
		ORDER BY ConsumerCombinationID DESC
	) c
	WHERE i.Narrative LIKE 'PAYPAL%' AND i.ConsumerCombinationID IS NULL 
		AND EXISTS (SELECT 1
					FROM #PaypalMIDNew pmn
					WHERE i.MID = pmn.MID)
		AND NOT EXISTS (SELECT 1
						FROM [staging].[BrandMatch] bm
						WHERE i.Narrative LIKE bm.Narrative
						AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal

--	If there are PayPal trans with <10 trans per MID remaining that don't have a CC, create one & assign it

	--ALTER INDEX [IX_NCL_Relational_ConsumerCombination_Matching] ON [Relational].[ConsumerCombination] DISABLE
	--ALTER INDEX [IX_Relational_ConsumerCombination] ON [Relational].[ConsumerCombination] DISABLE
		
DECLARE @RowsAffected INT

INSERT INTO [Relational].[ConsumerCombination] (
	BrandMIDID,	BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
OUTPUT 
	inserted.ConsumerCombinationID,  
	inserted.LocationCountry,   
	inserted.MCCID,  
	inserted.OriginatorID,  
	inserted.MID,  
	inserted.Narrative
INTO #PaypalCombosNonDefault (ConsumerCombinationID, LocationCountry, MCCID, OriginatorID, MID, Narrative)
SELECT DISTINCT -- 
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
FROM [Staging].[CTLoad_InitialStage] i WITH (TABLOCK)
WHERE i.Narrative LIKE 'PAYPAL%' AND i.ConsumerCombinationID IS NULL 
AND EXISTS (SELECT 1
			FROM #PaypalMIDNew pmn
			WHERE i.MID = pmn.MID)
AND NOT EXISTS (SELECT 1
				FROM [staging].[BrandMatch] bm
				WHERE i.Narrative LIKE bm.Narrative
				AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal
ORDER BY LocationCountry, MCCID, OriginatorID
SET @RowsAffected = @@ROWCOUNT
		
--ALTER INDEX [IX_NCL_Relational_ConsumerCombination_Matching] ON [Relational].[ConsumerCombination] REBUILD
--ALTER INDEX [IX_Relational_ConsumerCombination] ON [Relational].[ConsumerCombination] REBUILD

IF @RowsAffected > 0 BEGIN

	UPDATE i SET	
		ConsumerCombinationID = c.ConsumerCombinationID, 
		RequiresSecondaryID = 1
	FROM [Staging].[CTLoad_InitialStage] i WITH (TABLOCK)
	CROSS APPLY ( -- non-deterministic UPDATE
		SELECT TOP(1) c.ConsumerCombinationID
		FROM #PaypalCombosNonDefault c
		WHERE i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorID = c.OriginatorID	
		ORDER BY c.ConsumerCombinationID DESC			
	) c
	WHERE i.Narrative LIKE 'PAYPAL%' AND i.ConsumerCombinationID IS NULL 
	AND EXISTS (SELECT 1
				FROM #PaypalMIDNew pmn
				WHERE i.MID = pmn.MID)
	AND NOT EXISTS (SELECT 1
					FROM [staging].[BrandMatch] bm
					WHERE i.Narrative LIKE bm.Narrative
					AND bm.BrandID NOT IN (1797, 943)) --Etsy, PayPal
END

END