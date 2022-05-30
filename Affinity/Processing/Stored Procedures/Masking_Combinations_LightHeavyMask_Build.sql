
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description: Clears, inserts and recreates indexes on table to hold Combinations
				that were successfully light masked based on the specification.

				These include those that were already heavy masked (due to current logic
				they do not overlap however, the specification requires the heavy mask
				pass through)

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_Combinations_LightHeavyMask_Build]
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.Masking_CombinationsLightHeavyMask;

	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'cix_Processing_masking_lightheavymask'
				AND object_id = OBJECT_ID('Processing.Masking_CombinationsLightHeavyMask')
		)
		DROP INDEX cix_Processing_masking_lightheavymask ON Processing.Masking_CombinationsLightHeavyMask


	----------------------------------------------------------------------
	-- Build combinations that are applicable for light masking based on the specification
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Masking_CombinationsToMask') IS NOT NULL
		DROP TABLE #Masking_CombinationsToMask

	SELECT
		ctm.*
	INTO #Masking_CombinationsToMask
	FROM (
		-- Get combinations that havent been heavy masked
		-- and then append the masked narratives of the heavy masked combinations
		SELECT
			ConsumerCombinationID
		  , Narrative
		  , LocationCountry
		  , MCCID
		  , MID
		  , isGB
		  , CAST(0 AS BIT) AS isHeavyMasked
		FROM Processing.Masking_CombinationsToLightHeavyMask m
		WHERE NOT EXISTS
			(
				SELECT
					1
				FROM Processing.Masking_CombinationsHeavyMask hmc
				WHERE hmc.ConsumerCombinationID = m.ConsumerCombinationID
			)

		UNION ALL

		SELECT
			ConsumerCombinationID
		  , MaskedNarrative
		  , LocationCountry
		  , MCCID
		  , MID
		  , isGB
		  , CAST(1 AS BIT) AS isHeavyMasked
		FROM Processing.Masking_CombinationsHeavyMask
	) ctm -- Combinations that have
	LEFT JOIN Processing.Masking_MIDTransactionCount mtc
		ON ctm.MID = mtc.MID
			AND ctm.isGB = mtc.isGB
			AND mtc.DateType = 'L1M'
	WHERE EXISTS
		( -- a MCC that is in the list to be lightmasked
			SELECT
				1
			FROM dbo.Masking_MCCRules mcr
			WHERE ctm.MCCID = mcr.MCCID
				AND mcr.isHeavyMaskRule = 0
		)
		AND (mtc.TranCount < 40 -- and has a transaction count that is less than 40
			OR mtc.TranCount IS NULL)

	CREATE CLUSTERED INDEX cix_tempdb_masking_combos ON #Masking_CombinationsToMask (ConsumerCombinationID)

	----------------------------------------------------------------------
	-- Get names that are used for checking narrative
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Masking_NameDictionary') IS NOT NULL
		DROP TABLE #Masking_NameDictionary

	SELECT
		Unmasked
	  , LightMask
	  , NameLen
	INTO #Masking_NameDictionary
	FROM Processing.Masking_NameDictionary
	WHERE isLastName = 1
		AND NameLen >= 5

	CREATE CLUSTERED INDEX cx_tempdb_lightmaskdict ON #Masking_NameDictionary (Unmasked, LightMask) WITH (DATA_COMPRESSION = PAGE)

	----------------------------------------------------------------------
	-- Get combinations that have a name that appears anywhere in the narrative
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#LightMask_Staging') IS NOT NULL
		DROP TABLE #LightMask_Staging

	SELECT
		ctm.ConsumerCombinationID
	  , ctm.Narrative
	  , mnd.Unmasked
	  , mnd.LightMask
	  , ctm.LocationCountry
	  , ctm.MCCID
	  , ctm.MID
	  , mnd.NameLen
	  , ctm.isHeavyMasked
	INTO #LightMask_Staging
	FROM #Masking_CombinationsToMask ctm
	INNER JOIN #Masking_NameDictionary mnd -- for combinations that contain a last name
		ON ctm.Narrative LIKE '%' + mnd.Unmasked + '%'

	----------------------------------------------------------------------
	-- And then get those that match a narrative according the specification
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#LightMask') IS NOT NULL
		DROP TABLE #LightMask

	SELECT
		*
	  , rw =  ROW_NUMBER() OVER (
		PARTITION BY ConsumerCombinationID
		ORDER BY NameLen ASC)  --  ASC will make it so the longest name is the first replacement
	  , mrw = COUNT(*) OVER (PARTITION BY ConsumerCombinationID) -- Sets starting point for cte
	INTO #LightMask
	FROM #LightMask_Staging lms
	WHERE Narrative LIKE '% ' + Unmasked + ' %' -- the name is surrounded by spaces
		OR Narrative LIKE '% ' + Unmasked -- the name follows a space and is at the end of the narrative
		OR Narrative LIKE Unmasked + ' %' -- the name is followed by a space and is at the start of the narrative

	CREATE UNIQUE CLUSTERED INDEX ucx_tempdb_light_mask ON #LightMask (ConsumerCombinationID, rw)

	----------------------------------------------------------------------
	-- Perform light masking
		-- Will loop through each name match found and attempt to perform a replacement
		-- So that narratives that match multiple names will all be replaced
	----------------------------------------------------------------------
	;
	WITH LightMaskCleaned
	AS
	(
		-- Perform replacements on the longest match first
		SELECT
			ConsumerCombinationID
		  , Narrative
		  , REPLACE(Narrative, Unmasked, LightMask) MaskedNarrative
		  , rw
		  , mrw
		  , LocationCountry
		  , MCCID
		  , MID
		  , h.isHeavyMasked
		FROM #LightMask h
		WHERE h.rw = mrw

		UNION ALL

		-- Then for each additional match, attempt to perform the replacement
		SELECT
			h.ConsumerCombinationID
		  , h.Narrative
		  , REPLACE(hc.MaskedNarrative, h.Unmasked, h.LightMask) AS MaskedNarrative
		  , hc.rw - 1
		  , h.mrw
		  , h.LocationCountry
		  , h.MCCID
		  , h.MID
		  , h.isHeavyMasked
		FROM #LightMask h
		JOIN LightMaskCleaned hc
			ON hc.ConsumerCombinationID = h.ConsumerCombinationID
		WHERE h.rw = hc.rw - 1 -- negative indexing so that rw = 1 == final result

	)
	INSERT INTO Processing.Masking_CombinationsLightHeavyMask
	 SELECT
		 ConsumerCombinationID
	   , Narrative
	   , MaskedNarrative
	   , LocationCountry
	   , MCCID
	   , MID
	   , isHeavyMasked
	 FROM LightMaskCleaned
	 WHERE rw = 1 -- The final version with all possible replacements applied

	 SELECT @RowCount = @@rowcount

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	CREATE UNIQUE CLUSTERED INDEX cix_Processing_masking_lightheavymask ON Processing.Masking_CombinationsLightHeavyMask (ConsumerCombinationID)

	RETURN @RowCount
END
