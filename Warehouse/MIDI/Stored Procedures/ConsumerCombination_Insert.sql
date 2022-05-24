
-- =============================================
-- Author:		Rory Francis
-- Create date: 2019-04-18
-- Description:	Update MIDI results from the output of manual review

-- Change log:	

-- =============================================
CREATE PROCEDURE [MIDI].[ConsumerCombination_Insert]

AS
BEGIN

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF OBJECT_ID('tempdb..#CTLoad_MIDINewCombo') IS NOT NULL DROP TABLE #CTLoad_MIDINewCombo
	SELECT	ID = ROW_NUMBER() OVER (ORDER BY BrandID, MID, Narrative, MCCID, OriginatorID, LocationCountry)
		,	BrandID
		,	MID
		,	Narrative
		,	LocationCountry
		,	MCCID
		,	OriginatorID
		,	IsHighVariance
		,	IsUKSpend
		,	PaymentGatewayStatusID
		,	IsCreditOrigin
	INTO #CTLoad_MIDINewCombo
	FROM (	SELECT	BrandID = UpdatedBrandID
				,	MID
				,	Narrative = UpdatedNarrative
				,	LocationCountry
				,	MCCID
				,	OriginatorID
				,	IsHighVariance
				,	IsUKSpend = CONVERT(BIT, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END)
				,	PaymentGatewayStatusID = CONVERT(TINYINT, 2)
				,	IsCreditOrigin = CONVERT(BIT, MAX(CONVERT(INT, mnc.IsCreditOrigin)))
			FROM [MIDI].[CTLoad_MIDINewCombo] mnc
			WHERE UpdatedBrandID = 943
			GROUP BY	UpdatedBrandID
					,	MID
					,	UpdatedNarrative
					,	LocationCountry
					,	MCCID
					,	OriginatorID
					,	IsHighVariance
			UNION ALL
			SELECT	BrandID = UpdatedBrandID
				,	MID
				,	Narrative = UpdatedNarrative
				,	LocationCountry
				,	MCCID
				,	OriginatorID
				,	IsHighVariance
				,	IsUKSpend = CONVERT(BIT, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END)
				,	PaymentGatewayStatusID = CONVERT(TINYINT, 0)
				,	IsCreditOrigin = CONVERT(BIT, MAX(CONVERT(INT, mnc.IsCreditOrigin)))
			FROM [MIDI].[CTLoad_MIDINewCombo] mnc
			WHERE UpdatedBrandID != 943
			GROUP BY	UpdatedBrandID
					,	MID
					,	UpdatedNarrative
					,	LocationCountry
					,	MCCID
					,	OriginatorID
					,	IsHighVariance) cc
			
	CREATE CLUSTERED INDEX CIX_All ON #CTLoad_MIDINewCombo ([MID],[LocationCountry],[MCCID],[OriginatorID],[Narrative])
		
	IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
	SELECT	DISTINCT
			MID
		,	Narrative
		,	LocationCountry
		,	MCCID
		,	OriginatorID
	INTO #ConsumerCombination
	FROM [Warehouse].[Relational].[ConsumerCombination] cc
	WHERE EXISTS (	SELECT 1
					FROM #CTLoad_MIDINewCombo mnc
					WHERE cc.MID = mnc.MID
					AND cc.MCCID = mnc.MCCID
					AND cc.LocationCountry = mnc.LocationCountry
					AND cc.OriginatorID = mnc.OriginatorID)

	CREATE CLUSTERED INDEX CIX_All ON #ConsumerCombination ([MID],[LocationCountry],[MCCID],[OriginatorID],[Narrative])

	IF OBJECT_ID('tempdb..#CTLoad_MIDINewCombo_V2') IS NOT NULL DROP TABLE #CTLoad_MIDINewCombo_V2
	SELECT	BrandID
		,	MID
		,	Narrative
		,	LocationCountry
		,	MCCID
		,	OriginatorID
		,	IsHighVariance
		,	IsUKSpend
		,	PaymentGatewayStatusID
		,	IsCreditOrigin
	INTO #CTLoad_MIDINewCombo_V2
	FROM #CTLoad_MIDINewCombo mnc
	WHERE NOT EXISTS (	SELECT 1
						FROM #ConsumerCombination cc
						WHERE mnc.MID = cc.MID
						AND cc.Narrative LIKE mnc.Narrative
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID)


	SELECT	DISTINCT
			BrandID
		,	MID
		,	Narrative
		,	LocationCountry
		,	MCCID
		,	OriginatorID
		,	IsHighVariance
		,	IsUKSpend
		,	PaymentGatewayStatusID
		,	IsCreditOrigin
	FROM #CTLoad_MIDINewCombo_V2
	ORDER BY	BrandID
			,	MID
			,	Narrative
			,	MCCID
			,	OriginatorID
			,	LocationCountry

END
