
-- =============================================
-- Author:		Rory Francis
-- Create date: 2019-04-18
-- Description:	Update MIDI results from the output of manual review

-- Change log:	

-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_InsertNewCombinations]

AS
BEGIN

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF OBJECT_ID('tempdb..#CTLoad_MIDINewCombo_V2') IS NOT NULL DROP TABLE #CTLoad_MIDINewCombo_V2
	SELECT DISTINCT 
		   SuggestedBrandID AS BrandID
		 , MID
		 , Narrative
		 , LocationCountry
		 , MCCID
		 , OriginatorID
		 , IsHighVariance
		 , CONVERT(BIT, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END) AS IsUKSpend
		 , CONVERT(TINYINT, 2) AS PaymentGatewayStatusID
		 , IsCreditOrigin
	INTO #CTLoad_MIDINewCombo_V2
	FROM Staging.CTLoad_MIDINewCombo_V2 mnc
	WHERE SuggestedBrandID = 943
	AND NOT EXISTS (SELECT 1
					FROM [Warehouse].[Relational].[ConsumerCombination] cc
					WHERE mnc.MID = cc.MID
					AND mnc.Narrative = cc.Narrative
					AND mnc.LocationCountry = cc.LocationCountry
					AND mnc.MCCID = cc.MCCID
					AND mnc.OriginatorID = cc.OriginatorID)
	UNION ALL
	SELECT DISTINCT
		   SuggestedBrandID AS BrandID
		 , MID
		 , Narrative
		 , LocationCountry
		 , MCCID
		 , OriginatorID
		 , IsHighVariance
		 , CONVERT(BIT, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END) AS IsUKSpend
		 , CONVERT(TINYINT, 0) AS PaymentGatewayStatusID
		 , IsCreditOrigin
	FROM Staging.CTLoad_MIDINewCombo_V2 mnc
	WHERE SuggestedBrandID != 943
	AND NOT EXISTS (SELECT 1
					FROM [Warehouse].[Relational].[ConsumerCombination] cc
					WHERE mnc.MID = cc.MID
					AND mnc.Narrative = cc.Narrative
					AND mnc.LocationCountry = cc.LocationCountry
					AND mnc.MCCID = cc.MCCID
					AND mnc.OriginatorID = cc.OriginatorID)
				
	CREATE CLUSTERED INDEX CIX_BrandMIDNarrative ON #CTLoad_MIDINewCombo_V2 (BrandID, MID, Narrative, MCCID, OriginatorID)

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
	FROM #CTLoad_MIDINewCombo_V2
	ORDER BY	BrandID
			,	MID
			,	Narrative
			,	MCCID
			,	OriginatorID

END