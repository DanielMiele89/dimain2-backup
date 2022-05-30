
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description:	Clears, inserts and recreates indexes on table to hold ConsumerCombinations 
				that are candidates for masking i.e. those that are not exempt according to the specification

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]
******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_CombinationsToMask_Build]
AS
BEGIN

	DECLARE @NonBrandedIDs VARCHAR(MAX) = '944,943,1293'

	------------------------------------------------------------------------
	---- Clear down
	------------------------------------------------------------------------
	TRUNCATE TABLE Processing.Masking_CombinationsToMask;
	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'cix_masking_combinationstomask'
				AND object_id = OBJECT_ID('Processing.Masking_CombinationsToMask')
		)
		DROP INDEX cix_masking_combinationstomask ON Processing.Masking_CombinationsToMask


	----------------------------------------------------------------------
	-- Exempt IF Branded
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#CombosToMask') IS NOT NULL
		DROP TABLE #CombosToMask

	SELECT *, CAST(0 AS BIT) AS isSensitiveMask
	INTO #CombosToMask
	FROM Processing.Masking_ConsumerCombinations
	WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR(5)) + ',', ',' + @NonBrandedIDs + ',') > 0  -- Non-branded

	----------------------------------------------------------------------
	-- Exempt if LIMITED Narrative
	----------------------------------------------------------------------
	DELETE FROM #CombosToMask
	WHERE (
		Narrative LIKE '%LTD%'
		OR Narrative LIKE '%LIMITED%'
		OR Narrative LIKE '%LIMITE'
		OR Narrative LIKE '% LT'
	)

	----------------------------------------------------------------------
	-- Mark those for Sensitive Masking
	----------------------------------------------------------------------

	UPDATE c 
	SET isSensitiveMask = 1
	FROM #CombosToMask c
	WHERE EXISTS (
			SELECT
				1
			FROM dbo.Masking_NarrativeRules mnr
			WHERE c.Narrative LIKE mnr.NarrativeRule
				AND mnr.isHeavyMaskRule = 1
		)
		
	----------------------------------------------------------------------
	-- Exempt Branded MIDs that are not sensitive
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#BrandedMIDs') IS NOT NULL
		DROP TABLE #BrandedMIDs

	SELECT DISTINCT
		MID
	INTO #BrandedMIDs
	FROM Processing.Masking_ConsumerCombinations MCC
	WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR(5)) + ',', ',' + @NonBrandedIDs + ',') = 0 -- Branded

	CREATE CLUSTERED INDEX CIX_tempdb_MID ON #BrandedMIDs (MID)

	DELETE c FROM #CombosToMask c
	WHERE EXISTS (
		SELECT 1 FROM #BrandedMIDs b
		WHERE c.MID = b.MID
	)
		AND isSensitiveMask = 0

	----------------------------------------------------------------------
	-- Exempt MID if it passes Transaction Thresholds and is not sensitive
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#ExemptTransactionMIDs') IS NOT NULL
	DROP TABLE #ExemptTransactionMIDs

	SELECT DISTINCT
		MID
	  , isGB
	INTO #ExemptTransactionMIDs
	FROM Processing.Masking_MIDTransactionCount
	WHERE (isGB = 1
			AND (
				(DateType = 'L5Y'
					AND TranCount > 15000)
				OR (DateType = 'L12M'
					AND TranCount > 3500)
				OR (DateType = 'L1M'
					AND TranCount > 300)
				OR (DateType LIKE 'R%M'
					AND TranCount > 250)
			)
		)
		OR (isGB = 0
			AND (
				(DateType = 'L5Y'
					AND TranCount > 1500)
				OR (DateType = 'L12M'
					AND TranCount > 350)
				OR (DateType = 'L1M'
					AND TranCount > 30)
				OR (DateType LIKE 'R%M'
					AND TranCount > 25)
			)
		)

	CREATE CLUSTERED INDEX tempdb_ExemptMIDs ON #ExemptTransactionMIDs (MID, isGB)

	DELETE c FROM #CombosToMask c
	WHERE EXISTS (
		select 1 FROM #ExemptTransactionMIDs b
		WHERE c.MID = b.MID
		AND c.isGB = b.isGB
	)
		AND isSensitiveMask = 0
	
	----------------------------------------------------------------------
	-- Insert into Table
	----------------------------------------------------------------------
	INSERT INTO Processing.Masking_CombinationsToMask
	(
		ConsumerCombinationID
	  , Narrative
	  , MCCID
	  , LocationCountry
	  , MID
	  , isGB
	  , isBlanketMask
	  , isSensitiveMask
	)
	 SELECT
		 cc.ConsumerCombinationID
	   , cc.Narrative
	   , cc.MCCID
	   , cc.LocationCountry
	   , cc.MID
	   , cc.isGB
	   , cc.isBlanketMask
	   , cc.isSensitiveMask
	 FROM #CombosToMask cc

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	CREATE CLUSTERED INDEX cix_masking_combinationstomask ON [Processing].[Masking_CombinationsToMask]
	(
		[ConsumerCombinationID] ASC
	)


	RETURN @@rowcount

END


