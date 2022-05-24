-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_CombinationsNonPaypal_Set_DIMAIN]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
	SELECT	ConsumerCombinationID = MAX(ConsumerCombinationID)
		,	IsHighVariance
		,	MID
		,	Narrative
		,	LocationCountry
		,	MCCID
		,	OriginatorID
	INTO #ConsumerCombination
	FROM [Relational].[ConsumerCombination] cc
	WHERE PaymentGatewayStatusID != 1 -- not default Paypal
	AND EXISTS (SELECT 1
				FROM [Staging].[CTLoad_InitialStage] ct
				WHERE cc.MID = ct.MID
				AND cc.OriginatorID = ct.OriginatorID)
	GROUP BY	IsHighVariance
			,	MID
			,	Narrative
			,	LocationCountry
			,	MCCID
			,	OriginatorID

	CREATE CLUSTERED INDEX CIX_All ON #ConsumerCombination (IsHighVariance, MID, Narrative, LocationCountry, MCCID, OriginatorID, ConsumerCombinationID)
	
    UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_InitialStage i WITH (TABLOCK)
	CROSS APPLY ( -- non-deterministic update
		SELECT TOP(1) ConsumerCombinationID
		FROM #ConsumerCombination c 
		WHERE c.IsHighVariance = 0
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
		FROM #ConsumerCombination c 
		WHERE c.IsHighVariance = 1
			AND i.MID = c.MID
			AND i.Narrative LIKE c.Narrative -- ##
			AND i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorID = c.OriginatorID
		ORDER BY ConsumerCombinationID DESC
	) c
	WHERE i.ConsumerCombinationID IS NULL

END