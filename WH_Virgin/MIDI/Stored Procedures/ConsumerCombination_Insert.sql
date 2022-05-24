
-- =============================================
-- Author:		Rory Francis
-- Create date: Jan 1st 2021
-- Description:	Take all combinations that have gone through the manual midi process
--				and create permanent [ConsumerCombination] entries

-- Change log:	

-- =============================================

CREATE PROCEDURE [MIDI].[ConsumerCombination_Insert] 
AS
BEGIN
	
IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
SELECT	DISTINCT 
		UpdatedBrandID AS BrandID
	,	MID
	,	UpdatedNarrative
	,	LocationCountry
	,	MCCID
	,	IsHighVariance
	,	IsUKSpend
	,	CASE
			WHEN UpdatedBrandID = 943 THEN CONVERT(TINYINT, 2)
			WHEN OriginalNarrative LIKE 'PP*%' THEN CONVERT(TINYINT, 2)
			WHEN OriginalNarrative LIKE 'PayPal*%' THEN CONVERT(TINYINT, 2)
			ELSE CONVERT(TINYINT, 0)
		END AS PaymentGatewayStatusID
INTO #ConsumerCombination
FROM [MIDI].[CTLoad_MIDINewCombo] mnc
WHERE NOT EXISTS (	SELECT 1
					FROM [Trans].[ConsumerCombination] cc
					WHERE mnc.MID = cc.MID
					AND mnc.UpdatedNarrative = cc.Narrative
					AND mnc.LocationCountry = cc.LocationCountry
					AND mnc.MCCID = cc.MCCID)
		
SELECT	cc.BrandID
	,	cc.MID
	,	cc.UpdatedNarrative
	,	cc.LocationCountry
	,	cc.MCCID
	,	cc.IsHighVariance
	,	cc.IsUKSpend
	,	cc.PaymentGatewayStatusID
FROM #ConsumerCombination cc
ORDER BY	(SELECT BrandName FROM [Warehouse].[Relational].[Brand] br WHERE cc.BrandID = br.BrandID)
		,	cc.MID
		,	cc.UpdatedNarrative


END