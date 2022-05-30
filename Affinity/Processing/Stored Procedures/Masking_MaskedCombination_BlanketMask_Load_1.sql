
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description:	Inserts Non-GB ConsumerCombinations that are flagged for blanket masking
				with their narrative masked according to the specification

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_MaskedCombination_BlanketMask_Load]
AS
BEGIN

	----------------------------------------------------------------------
	-- Build Combinations to Mask
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#NonGBCombos') IS NOT NULL
		DROP TABLE #NonGBCombos

	SELECT
		*
	  , NarrL = CASE WHEN mn.NRule IS NULL THEN LEFT(Narrative, 2) ELSE mn.NRule END -- The unmasked section of the narrative
	  , NarrMask = CASE  -- The section be blanket masked
					WHEN mn.NRule IS NULL 
						THEN CAST(STUFF(Narrative, 1, 2, '') AS VARCHAR(50))
					ELSE REPLACE(Narrative, mn.NRule, '')
				   END
	  , DATALENGTH(Narrative) NarrLen
	INTO #NonGBCombos
	FROM Processing.Masking_CombinationsToMask ctm
	OUTER APPLY (
		SELECT nRule + LEFT(REPLACE(ctm.Narrative, nRule, ''),2) -- the rule + 2 characters
		FROM 
		(
			SELECT REPLACE(mnr.NarrativeRule, '%', '')
			FROM dbo.Masking_NarrativeRules mnr
			WHERE ctm.Narrative LIKE mnr.NarrativeRule
		)x (nRule)
	) mn(NRule)
	WHERE isBlanketMask = 1

	----------------------------------------------------------------------
	-- Perform Masking
	----------------------------------------------------------------------
	DECLARE @StrLen INT
	SELECT @StrLen = MAX(NarrLen) FROM #NonGBCombos

	;
	WITH tallyTable
	AS
	(
		SELECT
			0 AS n

		UNION ALL

		SELECT
			n + 1
		FROM tallyTable
		WHERE n <= @StrLen
	)
	INSERT INTO dbo.ConsumerCombination_Masked
	(
		ConsumerCombinationID
	  , Narrative
	  , MCCID
	  , LocationCountry
	  , MID
	  , MaskedNarrative
	  , isBlanketMasked
	  , isSensitiveMasked
	  , isHeavyMasked
	  , isLightMasked
	)
	 SELECT
		 ConsumerCombinationID
	   , Narrative
	   , MCCID
	   , LocationCountry
	   , MID
	   , REPLACE(REPLACE(c.NarrL + COALESCE(STUFF(narrMask.MaskedNarrative, 1, 1, ''), ''), '&#x20;', ' '), '&amp;', '&') AS MaskedNarrative
	   , 1
	   , 0
	   , 0
	   , 0
	 FROM #NonGBCombos c
	 CROSS APPLY (
		 SELECT
			 CASE
				 WHEN n > 0
					 AND (SUBSTRING(c.NarrMask, n * 2, 1) = NCHAR(32)) -- if space to replace
				  THEN SUBSTRING(c.NarrMask, n * 2, 2) -- skip replacement
				 ELSE '_' + SUBSTRING(c.NarrMask, 1 + n * 2, 1)
			 END -- get 1 character from every two and prefix with _ effectively turning one character into _
		 FROM tallyTable t
		 WHERE n < DATALENGTH(c.NarrMask) / 2 + 1
		 ORDER BY n
		 FOR XML PATH ('')
	 ) narrMask (MaskedNarrative)

	RETURN @@rowcount

END
