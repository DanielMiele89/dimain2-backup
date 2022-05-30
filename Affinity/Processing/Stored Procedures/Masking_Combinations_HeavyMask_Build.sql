
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description: Clears, inserts and recreates indexes on table to hold Combinations
				that were successfully heavy masked based on the specification

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_Combinations_HeavyMask_Build]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------

	TRUNCATE TABLE Processing.Masking_CombinationsHeavyMask;

	IF EXISTS (
		SELECT 1
		FROM sys.indexes 
		WHERE name='cix_Processing_masking_heavymask' AND object_id = OBJECT_ID('Processing.Masking_CombinationsHeavyMask')
	)
		DROP INDEX cix_Processing_masking_heavymask ON Processing.Masking_CombinationsHeavyMask
 

	----------------------------------------------------------------------
	-- Build Combinations that are applicable to be candidates for heavy masking
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Masking_CombinationsToMask') IS NOT NULL
		DROP TABLE #Masking_CombinationsToMask
	SELECT ctm.*
	INTO #Masking_CombinationsToMask
	FROM Processing.Masking_CombinationsToLightHeavyMask ctm
	WHERE (
		EXISTS (
			SELECT 1 FROM dbo.Masking_MCCRules mcr
			WHERE mcr.MCCID = ctm.MCCID
				AND mcr.isHeavyMaskRule = 1
		)
	)

	CREATE UNIQUE CLUSTERED INDEX cix_tempdb_masking_combinations ON #Masking_CombinationsToMask (ConsumerCombinationID)

	----------------------------------------------------------------------
	-- Get names to use for checking narratives
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Masking_NameDictionary') IS NOT NULL
		DROP TABLE #Masking_NameDictionary

	SELECT Unmasked, HeavyMask, NameLen
	INTO #Masking_NameDictionary
	FROM Processing.Masking_NameDictionary
	WHERE isLastName = 1
		AND NameLen >=5

	CREATE CLUSTERED INDEX cx_tempdb_heavymaskdict ON #Masking_NameDictionary (Unmasked, HeavyMask) WITH (DATA_COMPRESSION = PAGE)

	----------------------------------------------------------------------
	-- Check if names appear anywhere in the narrative
		-- This is a LIKE in the middle of a string and such, will take
		-- a considerably long time
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#HeavyMask_Staging') IS NOT NULL
		DROP TABLE #HeavyMask_Staging

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
	INTO #HeavyMask_Staging
	FROM #Masking_CombinationsToMask ctm
	INNER JOIN #Masking_NameDictionary mnd
		ON ctm.Narrative like '%' + mnd.Unmasked + '%' 

	CREATE CLUSTERED INDEX ucx_tempdb_heavystage ON #HeavyMask_Staging (Narrative, Unmasked)

	----------------------------------------------------------------------
	-- Get the final set of combinations to mask
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#HeavyMask') IS NOT NULL
		DROP TABLE #HeavyMask

	SELECT 
		*
		, rw = ROW_NUMBER() OVER (
				PARTITION BY ConsumerCombinationID 
					ORDER BY NameLen ASC)  --  ASC will make it so the longest name is the first replacement
		, mrw = COUNT(*) OVER (PARTITION BY ConsumerCombinationID) -- Sets starting point for cte
	INTO #HeavyMask
	FROM #HeavyMask_Staging hms
	WHERE Narrative LIKE '% '+Unmasked+' %' -- The name has a space either side
		OR Narrative LIKE '% '+ Unmasked  -- The name ends the narrative and has a space before
		OR Narrative LIKE Unmasked + ' %' -- the name starts the narrative and ends with a space

	CREATE UNIQUE CLUSTERED INDEX ucx_tempdb_heavymask ON #HeavyMask(ConsumerCombinationID, rw)

	----------------------------------------------------------------------
	-- Perform heavy masking
		-- Will loop through each name match found and attempt to perform a replacement
		-- So that narratives that match multiple names will all be replaced
	----------------------------------------------------------------------
	;WITH HeavyMaskCleaned AS
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
		FROM #HeavyMask h
		WHERE h.rw = mrw

		UNION ALL

		-- Then for each additional match, attempt to perform the replacement
		SELECT
			h.ConsumerCombinationID
			, h.Narrative
			, REPLACE(hc.MaskedNarrative, h.Unmasked, h.HeavyMask) AS MaskedNarrative
			, hc.rw-1
			, h.mrw
			, h.LocationCountry
			, h.MCCID
			, h.MID
			, h.isGB
		FROM #HeavyMask h
		JOIN HeavyMaskCleaned hc
			ON hc.ConsumerCombinationID = h.ConsumerCombinationID
		WHERE h.rw = hc.rw - 1 -- negative indexing so that rw = 1 == final result
	)
	INSERT INTO Processing.Masking_CombinationsHeavyMask
	SELECT
		ConsumerCombinationID
		, Narrative
		, MaskedNarrative
		, LocationCountry
		, MCCID
		, MID
		, isGB
	FROM HeavyMaskCleaned
	WHERE rw = 1 -- The final version with all possible replacements applied

	SELECT @RowCount = @@Rowcount

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	CREATE UNIQUE CLUSTERED INDEX cix_Processing_masking_heavymask ON Processing.Masking_CombinationsHeavyMask (ConsumerCombinationID)

	RETURN @RowCount

END


