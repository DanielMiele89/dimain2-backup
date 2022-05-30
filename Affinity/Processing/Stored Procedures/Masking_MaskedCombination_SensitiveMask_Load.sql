
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description: Inserts Sensitive Narrative ConsumerCombinations that are flagged for masking
				with their narrative masked according to the specification 
------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_MaskedCombination_SensitiveMask_Load]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Get Combinations to Mask
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Masking_CombinationsToMask') IS NOT NULL
		DROP TABLE #Masking_CombinationsToMask
	SELECT
		ctm.*
		, RTRIM(LTRIM(Narrative)) TrimmedNarrative -- Trim the narrative for trailing spaces
	INTO #Masking_CombinationsToMask
	FROM Processing.Masking_CombinationsToMask ctm
	WHERE ctm.isSensitiveMask = 1 and ctm.isBlanketMask = 0

	CREATE CLUSTERED INDEX cix_tempdb_masking_combinations ON #Masking_CombinationsToMask (TrimmedNarrative)

	----------------------------------------------------------------------
	-- Get Names to use for narrative masking
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Masking_NameDictionary') IS NOT NULL
		DROP TABLE #Masking_NameDictionary

	SELECT
		Unmasked
	  , HeavyMask
	  , NameLen
	INTO #Masking_NameDictionary
	FROM Processing.Masking_NameDictionary
	WHERE isLastName = 1
		AND NameLen >= 5

	CREATE CLUSTERED INDEX cx_tempdb_heavymaskdict ON #Masking_NameDictionary (Unmasked, HeavyMask) WITH (DATA_COMPRESSION = PAGE)

	----------------------------------------------------------------------
	-- Get narratives that need to be replaced
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#SensiMask_Staging') IS NOT NULL
		DROP TABLE #SensiMask_Staging

	SELECT
		ctm.ConsumerCombinationID
	  , ctm.Narrative
	  , mnd.Unmasked
	  , mnd.HeavyMask
	  , ctm.LocationCountry
	  , ctm.MCCID
	  , ctm.MID
	  , mnd.NameLen
	  , ctm.isGB
	INTO #SensiMask_Staging
	FROM #Masking_CombinationsToMask ctm
	INNER JOIN #Masking_NameDictionary mnd
		ON ctm.TrimmedNarrative LIKE '%' + mnd.Unmasked -- the narrative matches the end of the narrative

	CREATE CLUSTERED INDEX ucx_tempdb_heavystage ON #SensiMask_Staging (ConsumerCombinationID)

	----------------------------------------------------------------------
	-- Get IDs to loop through for replacements
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#SensiMask') IS NOT NULL
		DROP TABLE #SensiMask

	SELECT
		*
	  , rw =  ROW_NUMBER() OVER (
		PARTITION BY ConsumerCombinationID
		ORDER BY NameLen ASC)  --  ASC will make it so the longest name is the first replacement
	  , mrw = COUNT(*) OVER (PARTITION BY ConsumerCombinationID) -- Sets starting point for cte
	INTO #SensiMask
	FROM #SensiMask_Staging hms

	CREATE UNIQUE CLUSTERED INDEX ucx_tempdb_heavymask ON #SensiMask (rw, ConsumerCombinationID)

	----------------------------------------------------------------------
	-- Perform sensitive masking
		-- Will loop through each name match found and attempt to perform a replacement
		-- So that narratives that match multiple names will all be replaced

		-- This is technically not required anymore after logic changes related to narrative matching because 
		-- the highest len name that matches is the only one that needs to be replaced
		-- however, if there are any changes, this will handle the duplicate replacement scenario
	----------------------------------------------------------------------
	;
	WITH SensiMaskCleaned
	AS
	(
		-- Perform replacements on the longest match first
		SELECT
			ConsumerCombinationID
		  , Narrative
		  , REPLACE(Narrative, Unmasked, HeavyMask) MaskedNarrative
		  , rw
		  , mrw
		  , LocationCountry
		  , MCCID
		  , MID
		  , isGB
		FROM #SensiMask h
		WHERE h.rw = mrw

		UNION ALL

		-- Then for each additional match, attempt to perform the replacement
		SELECT
			h.ConsumerCombinationID
		  , h.Narrative
		  , REPLACE(hc.MaskedNarrative, h.Unmasked, h.HeavyMask) AS MaskedNarrative
		  , hc.rw - 1
		  , h.mrw
		  , h.LocationCountry
		  , h.MCCID
		  , h.MID
		  , h.isGB
		FROM #SensiMask h
		JOIN SensiMaskCleaned hc
			ON hc.ConsumerCombinationID = h.ConsumerCombinationID
		WHERE h.rw = hc.rw - 1 -- negative indexing so that rw = 1 == final result
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
	   , MaskedNarrative
	   , 0
	   , 1
	   , 0
	   , 0
	 FROM SensiMaskCleaned
	 WHERE rw = 1 -- The final version with all possible replacements applied

	SELECT @RowCount = @@rowcount

	RETURN @RowCount

END
