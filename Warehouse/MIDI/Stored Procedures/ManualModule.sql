
CREATE PROCEDURE [MIDI].[ManualModule]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT
	
/*******************************************************************************************************************************************
	1.	Clear down Staging tables
*******************************************************************************************************************************************/

	TRUNCATE TABLE [MIDI].[CTLoad_MIDINewCombo_Branded]
	TRUNCATE TABLE [MIDI].[CTLoad_MIDINewCombo_PossibleBrands]
	TRUNCATE TABLE [MIDI].[CTLoad_MIDINewCombo]


/*******************************************************************************************************************************************
	2.	Check whether execution is necessary
*******************************************************************************************************************************************/

	SELECT @RowsAffected = SUM(TranCount) 
	FROM (	SELECT COUNT(*) AS TranCount
			FROM [Staging].[CTLoad_MIDIHolding]
			UNION ALL
			SELECT COUNT(*) AS TranCount
			FROM [Staging].[CreditCardLoad_MIDIHolding]) ct

	IF @RowsAffected = 0 BEGIN
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - No rows to process'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
		--RETURN
	END
	ELSE
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Starting manual module'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	

/*******************************************************************************************************************************************
	3.	Fetch new combinations that need to be branded
*******************************************************************************************************************************************/

	ALTER INDEX [ix_Stuff1] ON [MIDI].[CTLoad_MIDINewCombo] DISABLE
	ALTER INDEX [ix_Stuff2] ON [MIDI].[CTLoad_MIDINewCombo] DISABLE
	ALTER INDEX [ix_Stuff3] ON [MIDI].[CTLoad_MIDINewCombo] DISABLE

	INSERT INTO [MIDI].[CTLoad_MIDINewCombo] (	MID
											,	OriginalNarrative
											,	LocationCountry
											,	MCCID
											,	OriginatorID
											,	IsCreditOrigin
											,	MatchCount)
	SELECT	MID
		,	Narrative
		,	LocationCountry
		,	MCCID
		,	OriginatorID
		,	MIN(IsCreditOrigin) AS IsCreditOrigin
		,	SUM(MatchCount) AS MatchCount
	FROM	(	SELECT	MID
					,	Narrative
					,	LocationCountry
					,	MCCID
					,	OriginatorID
					,	0 AS IsCreditOrigin
					,	COUNT(*) AS MatchCount
				FROM [Staging].[CTLoad_MIDIHolding] mh
				WHERE ConsumerCombinationID IS NULL
				GROUP BY	MID
						,	Narrative
						,	LocationCountry
						,	MCCID
						,	OriginatorID
				UNION ALL
				SELECT	MID
					,	Narrative
					,	LocationCountry
					,	MCCID
					,	OriginatorReference
					,	1 AS IsCreditOrigin
					,	COUNT(*) AS MatchCount
				FROM [Staging].[CreditCardLoad_MIDIHolding] mh
				WHERE ConsumerCombinationID IS NULL
				GROUP BY	MID
						,	Narrative
						,	LocationCountry
						,	MCCID
						,	OriginatorReference) mh
	GROUP BY	MID
			,	Narrative
			,	LocationCountry
			,	MCCID
			,	OriginatorID
	ORDER BY	MID
			,	Narrative
			,	LocationCountry
			,	MCCID
			,	OriginatorID


	SET @RowsAffected = @@ROWCOUNT

	ALTER INDEX [ix_Stuff1] ON [MIDI].[CTLoad_MIDINewCombo] REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX [ix_Stuff2] ON [MIDI].[CTLoad_MIDINewCombo] REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX [ix_Stuff3] ON [MIDI].[CTLoad_MIDINewCombo] REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX [PK_MIDI_CTLoad_MIDINewCombo] ON [MIDI].[CTLoad_MIDINewCombo] REBUILD WITH (SORT_IN_TEMPDB = ON)

	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Collect rows to process [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	

/*******************************************************************************************************************************************
	4.	Clean the Narrative column to remove PSP prefixes (CRV*, IZ* etc)
*******************************************************************************************************************************************/

	UPDATE mnc
	SET	Narrative_Cleaned = ISNULL(x.Narrative_Cleaned, mnc.OriginalNarrative)
	FROM [MIDI].[CTLoad_MIDINewCombo] mnc -- 90,605
	OUTER APPLY [Warehouse].[dbo].[iTVF_NarrativeCleaner](-1,mnc.OriginalNarrative) q1
	OUTER APPLY [Warehouse].[dbo].[iTVF_NarrativeCleaner](q1.ID,q1.Narrative_Cleaned) q2
	OUTER APPLY [Warehouse].[dbo].[iTVF_NarrativeCleaner](q2.ID,q2.Narrative_Cleaned) q3
	CROSS APPLY (SELECT	Narrative_Cleaned = COALESCE(q3.Narrative_Cleaned, q2.Narrative_Cleaned, q1.Narrative_Cleaned, mnc.Narrative_Cleaned)) x

	SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative cleaner [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	-- (573814 rows affected) / 00:00:21
	

/*******************************************************************************************************************************************
	5.	Store Combinations & Lookups that are cross publisher
*******************************************************************************************************************************************/
	

		DECLARE @LastYear DATE = DATEADD(YEAR, -1, GETDATE())

		IF OBJECT_ID('tempdb..#Combinations') IS NOT NULL DROP TABLE #Combinations
		SELECT	DISTINCT
				BrandID
			,	MID
			,	Narrative
			,	Narrative AS Narrative_Cleaned
			,	LocationCountry
			,	MCCID
			,	OriginatorID
		INTO #Combinations
		FROM [Warehouse].[Relational].[ConsumerCombination] cc
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND EXISTS (SELECT 1
					FROM [Warehouse].[Relational].[ConsumerTransaction] ct
					WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID
					AND @LastYear <= ct.TranDate)
		UNION
		SELECT	DISTINCT
				BrandID
			,	MID
			,	Narrative
			,	Narrative AS Narrative_Cleaned
			,	LocationCountry
			,	MCCID
			,	OriginatorID
		FROM [Warehouse].[Relational].[ConsumerCombination] cc
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND EXISTS (SELECT 1
					FROM [Warehouse].[Relational].[ConsumerTransaction_CreditCard] ct
					WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID
					AND @LastYear <= ct.TranDate)
		UNION
		SELECT	DISTINCT
				BrandID
			,	MID
			,	Narrative
			,	Narrative AS Narrative_Cleaned
			,	LocationCountry
			,	MCCID
			,	NULL AS OriginatorID
		FROM [WH_Virgin].[Trans].[ConsumerCombination] cc
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND EXISTS (SELECT 1
					FROM [WH_Virgin].[Trans].[ConsumerTransaction] ct
					WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID
					AND @LastYear <= ct.TranDate)
		UNION
		SELECT	DISTINCT
				BrandID
			,	MID
			,	Narrative
			,	Narrative AS Narrative_Cleaned
			,	LocationCountry
			,	MCCID
			,	OriginatorID
		FROM [WH_Visa].[Trans].[ConsumerCombination] cc
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND EXISTS (SELECT 1
					FROM [WH_Visa].[Trans].[ConsumerTransaction] ct
					WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID
					AND @LastYear <= ct.TranDate)

							UPDATE mnc
		SET	Narrative_Cleaned = ISNULL(x.Narrative_Cleaned, mnc.Narrative)
		FROM #Combinations mnc -- 90,605
		OUTER APPLY [Warehouse].[dbo].[iTVF_NarrativeCleaner](-1,mnc.Narrative) q1
		OUTER APPLY [Warehouse].[dbo].[iTVF_NarrativeCleaner](q1.ID,q1.Narrative_Cleaned) q2
		OUTER APPLY [Warehouse].[dbo].[iTVF_NarrativeCleaner](q2.ID,q2.Narrative_Cleaned) q3
		CROSS APPLY (SELECT	Narrative_Cleaned = COALESCE(q3.Narrative_Cleaned, q2.Narrative_Cleaned, q1.Narrative_Cleaned, mnc.Narrative_Cleaned)) x
		
		SET @RowsAffected = @@ROWCOUNT

		CREATE NONCLUSTERED INDEX [ix_Stuff3] ON #Combinations ([LocationCountry] ASC, [MCCID] ASC, [MID] ASC, [Narrative] ASC)
		CREATE NONCLUSTERED INDEX [ix_Stuff4] ON #Combinations ([MID] ASC,[LocationCountry] ASC,[MCCID] ASC) INCLUDE([Narrative])
		CREATE NONCLUSTERED INDEX [ix_Stuff5] ON #Combinations ([BrandID] ASC) INCLUDE([MID],[MCCID])
		CREATE NONCLUSTERED INDEX [ix_Stuff6] ON #Combinations ([MID] ASC, [MCCID] ASC) INCLUDE([BrandID])

		CREATE CLUSTERED INDEX CIX_MID ON #Combinations (MID)

		DELETE
		FROM #Combinations
		WHERE Narrative_Cleaned IN ('SP * %', '%')

	--	CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #Combinations (BrandID, MID, Narrative, LocationCountry, MCCID)
	
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Store Combinations [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
		
		IF OBJECT_ID('tempdb..#NarrativeBrandLookup') IS NOT NULL DROP TABLE #NarrativeBrandLookup
		SELECT	DISTINCT
				BrandID
			,	Narrative
		INTO #NarrativeBrandLookup
		FROM [WH_Virgin].[MIDI].[BrandMatch]
		WHERE BrandID != 944
		UNION
		SELECT	DISTINCT
				BrandID
			,	Narrative
		FROM [Warehouse].[Staging].[BrandMatch]
		WHERE BrandID != 944
		UNION
		SELECT	DISTINCT
				BrandID
			,	Narrative
		FROM [WH_Visa].[MIDI].[BrandMatch]
		WHERE BrandID != 944
		
		SET @RowsAffected = @@ROWCOUNT

		CREATE CLUSTERED INDEX CIX_All ON #NarrativeBrandLookup (Narrative, BrandID)
		CREATE NONCLUSTERED INDEX IX_All ON #NarrativeBrandLookup (BrandID, Narrative)
		CREATE NONCLUSTERED INDEX IX_BrandID ON #NarrativeBrandLookup (BrandID)
		CREATE NONCLUSTERED INDEX IX_Narrative ON #NarrativeBrandLookup (Narrative)
	
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Store Lookups [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


/*******************************************************************************************************************************************
	6.	Run through various scenarios to suggest a BrandID in dreasing probability of a correct match
*******************************************************************************************************************************************/



				INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																		,	SuggestedBrandID
																		,	MatchTypeID
																		,	NarrativeMatchedOn)
				SELECT	DISTINCT 
						mnc.ID
					,	BrandID = 1809
					,	1 as MatchTypeID
					,	LEFT(OriginalNarrative, CHARINDEX(' ', OriginalNarrative)) + '_____' + SUBSTRING(OriginalNarrative, CHARINDEX(' ', OriginalNarrative) + 6, 9999)
				FROM [MIDI].[CTLoad_MIDINewCombo] mnc
				WHERE OriginalNarrative LIKE 'NOW _____ %'
				OR OriginalNarrative LIKE 'NOW _____'
				OR OriginalNarrative LIKE 'CRV*NOW _____'
				OR OriginalNarrative LIKE 'CRV*NOW _____ %'

				UPDATE mnc
				SET UpdatedNarrative = LEFT(OriginalNarrative, CHARINDEX(' ', OriginalNarrative)) + '_____' + SUBSTRING(OriginalNarrative, CHARINDEX(' ', OriginalNarrative) + 6, 9999)
				,	IsHighVariance = 1
				FROM [MIDI].[CTLoad_MIDINewCombo] mnc
				WHERE OriginalNarrative LIKE 'NOW _____ %'
				OR OriginalNarrative LIKE 'NOW _____'
				OR OriginalNarrative LIKE 'CRV*NOW _____'
				OR OriginalNarrative LIKE 'CRV*NOW _____ %'


				


	/***********************************************************************************************************************
		6.1.	Narratve, MID, MCC, Country, Originator
	***********************************************************************************************************************/

		--INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
		--														,	SuggestedBrandID
		--														,	MatchTypeID
		--														,	NarrativeMatchedOn)
		--SELECT	DISTINCT 
		--		mnc.ID
		--	,	cc.BrandID
		--	,	1 as MatchTypeID
		--	,	cc.Narrative_Cleaned
		--FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		--CROSS APPLY (	SELECT	TOP 1
		--						NULL AS IgnoreColumn
		--					,	cc.MID
		--					,	cc.Narrative_Cleaned
		--					,	cc.MCCID
		--					,	cc.LocationCountry
		--					,	cc.OriginatorID
		--					,	cc.BrandID
		--					,	CASE
		--							WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
		--							WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
		--							WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
		--							WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
		--							WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
		--							WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
		--						END AS MatchOrder
		--					,	COUNT(*) AS Matches
		--				FROM #Combinations cc
		--				WHERE 1 = 1
		--				AND mnc.MID = cc.MID
		--				AND mnc.LocationCountry = cc.LocationCountry
		--				AND mnc.MCCID = cc.MCCID
		--				AND mnc.OriginatorID = cc.OriginatorID
		--				AND (		mnc.OriginalNarrative = cc.Narrative
		--						OR	mnc.OriginalNarrative LIKE cc.Narrative
		--						OR	mnc.Narrative_Cleaned = cc.Narrative
		--						OR	mnc.Narrative_Cleaned LIKE cc.Narrative
		--						OR	mnc.Narrative_Cleaned = cc.Narrative
		--						OR	mnc.Narrative_Cleaned LIKE cc.Narrative
		--						OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
		--						OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
		--				--AND EXISTS (SELECT 1
		--				--			FROM #NarrativeBrandLookup nbl
		--				--			WHERE cc.BrandID = nbl.BrandID
		--				--			AND mnc.Narrative_Cleaned LIKE nbl.Narrative)
		--				AND cc.BrandID NOT IN (944, 943, 1293)
		--				GROUP BY	cc.BrandID
		--						,	cc.MID
		--						,	cc.Narrative_Cleaned
		--						,	cc.MCCID
		--						,	cc.LocationCountry
		--						,	cc.OriginatorID
		--						,	CASE
		--								WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
		--								WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
		--								WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
		--								WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
		--								WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
		--								WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
		--							END
		--				ORDER BY	(SELECT NULL)
		--						,	CASE
		--								WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
		--								WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
		--								WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
		--								WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
		--								WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
		--								WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
		--							END
		--						,	COUNT(*) DESC) cc
		--WHERE NOT EXISTS (	SELECT 1
		--					FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
		--					WHERE mnc.ID = pb.ComboID)
													

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	1 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						AND mnc.OriginalNarrative = cc.Narrative
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
						ORDER BY	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	1 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						AND mnc.OriginalNarrative LIKE cc.Narrative
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
						ORDER BY	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	1 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						AND mnc.Narrative_Cleaned = cc.Narrative
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
						ORDER BY	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	1 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						AND mnc.Narrative_Cleaned LIKE cc.Narrative
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
						ORDER BY	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	1 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						AND mnc.Narrative_Cleaned = cc.Narrative_Cleaned
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
						ORDER BY	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	1 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						AND mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
						ORDER BY	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

	/***********************************************************************************************************************
		6.2.	Brand Match Narrative, MID, MCC, Country, Originator
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	2 as MatchTypeID
			,	cc.Narrative
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	nbl.Narrative
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							--,	CASE
							--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
							--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
							--	END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup nbl
							ON cc.BrandID = nbl.BrandID
							AND mnc.Narrative_Cleaned LIKE nbl.Narrative
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						--AND (		mnc.OriginalNarrative = cc.Narrative
						--		OR	mnc.OriginalNarrative LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	nbl.Narrative
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
						ORDER BY (SELECT NULL)
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.3.	Narratve, MID, MCC, Country
				Excluding OriginatorID
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	3 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	cc.MCCID
							,	cc.LocationCountry
							--,	cc.OriginatorID
							,	cc.BrandID
							,	CASE
									WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
									WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
									WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
									WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						--AND mnc.OriginatorID = cc.OriginatorID
						AND (		mnc.OriginalNarrative = cc.Narrative
								OR	mnc.OriginalNarrative LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						--AND EXISTS (SELECT 1
						--			FROM #NarrativeBrandLookup nbl
						--			WHERE cc.BrandID = nbl.BrandID
						--			AND mnc.Narrative_Cleaned LIKE nbl.Narrative)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	cc.MCCID
								,	cc.LocationCountry
								--,	cc.OriginatorID
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
						ORDER BY	(SELECT NULL)
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.4.	Brand Match Narrative, MID, MCC, Country
				Excluding OriginatorID
	***********************************************************************************************************************/
	
		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	4 as MatchTypeID
			,	cc.Narrative
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	nbl.Narrative
							,	cc.MCCID
							,	cc.LocationCountry
							--,	cc.OriginatorID
							,	cc.BrandID
							--,	CASE
							--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
							--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
							--	END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup nbl
							ON cc.BrandID = nbl.BrandID
							AND mnc.Narrative_Cleaned LIKE nbl.Narrative
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						--AND mnc.OriginatorID = cc.OriginatorID
						--AND (		mnc.OriginalNarrative = cc.Narrative
						--		OR	mnc.OriginalNarrative LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	nbl.Narrative
								,	cc.MCCID
								,	cc.LocationCountry
								--,	cc.OriginatorID
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
						ORDER BY	(SELECT NULL)
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

	/***********************************************************************************************************************
		6.5.	Narratve, MID, Country, Originator
				Excluding MCCID
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	5 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							--,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							,	CASE
									WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
									WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
									WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
									WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						--AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						AND (		mnc.OriginalNarrative = cc.Narrative
								OR	mnc.OriginalNarrative LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						--AND EXISTS (SELECT 1
						--			FROM #NarrativeBrandLookup nbl
						--			WHERE cc.BrandID = nbl.BrandID
						--			AND mnc.Narrative_Cleaned LIKE nbl.Narrative)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								--,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
						ORDER BY	(SELECT NULL)
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.6.	Brand Match Narrative, MID, Country, Originator
				Excluding MCCID
	***********************************************************************************************************************/
	
		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	6 as MatchTypeID
			,	cc.Narrative
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	nbl.Narrative
							--,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							--,	CASE
							--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
							--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
							--	END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup nbl
							ON cc.BrandID = nbl.BrandID
							AND mnc.Narrative_Cleaned LIKE nbl.Narrative
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						--AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						--AND (		mnc.OriginalNarrative = cc.Narrative
						--		OR	mnc.OriginalNarrative LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	nbl.Narrative
								--,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
						ORDER BY	(SELECT NULL)
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.7.	Narratve, MCCID, Country, Originator
				Excluding MID
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	7 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							--,	cc.MID
							,	cc.Narrative_Cleaned
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							,	CASE
									WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
									WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
									WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
									WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						--AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						AND (		mnc.OriginalNarrative = cc.Narrative
								OR	mnc.OriginalNarrative LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						--AND EXISTS (SELECT 1
						--			FROM #NarrativeBrandLookup nbl
						--			WHERE cc.BrandID = nbl.BrandID
						--			AND mnc.Narrative_Cleaned LIKE nbl.Narrative)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								--,	cc.MID
								,	cc.Narrative_Cleaned
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
						ORDER BY	(SELECT NULL)
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.8.	Brand Match Narrative, MCCID, Country, Originator
				Excluding MID
	***********************************************************************************************************************/
	
		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	8 as MatchTypeID
			,	cc.Narrative
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							--,	cc.MID
							,	cc.Narrative_Cleaned
							,	nbl.Narrative
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.OriginatorID
							,	cc.BrandID
							--,	CASE
							--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
							--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
							--	END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup nbl
							ON cc.BrandID = nbl.BrandID
							AND mnc.Narrative_Cleaned LIKE nbl.Narrative
						WHERE 1 = 1
						--AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginatorID = cc.OriginatorID
						--AND (		mnc.OriginalNarrative = cc.Narrative
						--		OR	mnc.OriginalNarrative LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								--,	cc.MID
								,	cc.Narrative_Cleaned
								,	nbl.Narrative
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.OriginatorID
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
						ORDER BY	(SELECT NULL)
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.9.	Narratve, MID, Country
				Excluding MCCID, OriginatorID
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	9 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							--,	cc.MCCID
							,	cc.LocationCountry
							--,	cc.OriginatorID
							,	cc.BrandID
							,	CASE
									WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
									WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
									WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
									WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						--AND mnc.MCCID = cc.MCCID
						--AND mnc.OriginatorID = cc.OriginatorID
						AND (		mnc.OriginalNarrative = cc.Narrative
								OR	mnc.OriginalNarrative LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						--AND EXISTS (SELECT 1
						--			FROM #NarrativeBrandLookup nbl
						--			WHERE cc.BrandID = nbl.BrandID
						--			AND mnc.Narrative_Cleaned LIKE nbl.Narrative)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								--,	cc.MCCID
								,	cc.LocationCountry
								--,	cc.OriginatorID
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
						ORDER BY	(SELECT NULL)
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.10.	Brand Match Narrative, MID, Country
				Excluding MCCID, OriginatorID
	***********************************************************************************************************************/
	
		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	10 as MatchTypeID
			,	cc.Narrative
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	nbl.Narrative
							--,	cc.MCCID
							,	cc.LocationCountry
							--,	cc.OriginatorID
							,	cc.BrandID
							--,	CASE
							--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
							--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
							--	END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup nbl
							ON cc.BrandID = nbl.BrandID
							AND mnc.Narrative_Cleaned LIKE nbl.Narrative
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						--AND mnc.MCCID = cc.MCCID
						--AND mnc.OriginatorID = cc.OriginatorID
						--AND (		mnc.OriginalNarrative = cc.Narrative
						--		OR	mnc.OriginalNarrative LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	nbl.Narrative
								--,	cc.MCCID
								,	cc.LocationCountry
								--,	cc.OriginatorID
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
						ORDER BY	(SELECT NULL)
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.11.	Narrative, MID					--	Check ********
				Excluding MCCID, OriginatorID, Country
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	11 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							--,	cc.MCCID
							--,	cc.LocationCountry
							--,	cc.OriginatorID
							,	cc.BrandID
							,	CASE
									WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
									WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
									WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
									WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						--AND mnc.LocationCountry = cc.LocationCountry
						--AND mnc.MCCID = cc.MCCID
						--AND mnc.OriginatorID = cc.OriginatorID
						AND (		mnc.OriginalNarrative = cc.Narrative
								OR	mnc.OriginalNarrative LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative
								OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						--AND EXISTS (SELECT 1
						--			FROM #NarrativeBrandLookup nbl
						--			WHERE cc.BrandID = nbl.BrandID
						--			AND mnc.Narrative_Cleaned LIKE nbl.Narrative)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								--,	cc.MCCID
								--,	cc.LocationCountry
								--,	cc.OriginatorID
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
						ORDER BY	(SELECT NULL)
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.12.	Brand Match Narrative, MID
				Excluding MCCID, OriginatorID, Country
	***********************************************************************************************************************/
	
		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	12 as MatchTypeID
			,	cc.Narrative
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							,	cc.MID
							,	cc.Narrative_Cleaned
							,	nbl.Narrative
							--,	cc.MCCID
							--,	cc.LocationCountry
							--,	cc.OriginatorID
							,	cc.BrandID
							--,	CASE
							--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
							--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
							--	END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup nbl
							ON cc.BrandID = nbl.BrandID
							AND mnc.Narrative_Cleaned LIKE nbl.Narrative
						WHERE 1 = 1
						AND mnc.MID = cc.MID
						--AND mnc.LocationCountry = cc.LocationCountry
						--AND mnc.MCCID = cc.MCCID
						--AND mnc.OriginatorID = cc.OriginatorID
						--AND (		mnc.OriginalNarrative = cc.Narrative
						--		OR	mnc.OriginalNarrative LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								,	cc.MID
								,	cc.Narrative_Cleaned
								,	nbl.Narrative
								--,	cc.MCCID
								--,	cc.LocationCountry
								--,	cc.OriginatorID
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
						ORDER BY	(SELECT NULL)
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.13.	Narrative, MCCID					--	Check ********
				Excluding MID, OriginatorID, Country
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	13 as MatchTypeID
			,	cc.Narrative_Cleaned
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							--,	cc.MID
							,	cc.Narrative_Cleaned
							,	cc.MCCID
							--,	cc.LocationCountry
							--,	cc.OriginatorID
							,	cc.BrandID
							,	CASE
									WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
									WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
									WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
									WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
									WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE 1 = 1
						--AND mnc.MID = cc.MID
						--AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						--AND mnc.OriginatorID = cc.OriginatorID
						AND (		mnc.Narrative_Cleaned = cc.Narrative_Cleaned
								OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						--AND EXISTS (SELECT 1
						--			FROM #NarrativeBrandLookup nbl
						--			WHERE cc.BrandID = nbl.BrandID
						--			AND mnc.Narrative_Cleaned LIKE nbl.Narrative)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								--,	cc.MID
								,	cc.Narrative_Cleaned
								,	cc.MCCID
								--,	cc.LocationCountry
								--,	cc.OriginatorID
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
						ORDER BY	(SELECT NULL)
								,	CASE
										WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
										WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
										WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
									END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)


	/***********************************************************************************************************************
		6.14.	Brand Match Narrative, MCCID
				Excluding MID, OriginatorID, Country
	***********************************************************************************************************************/
	
		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	14 as MatchTypeID
			,	cc.Narrative
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								NULL AS IgnoreColumn
							--,	cc.MID
							,	cc.Narrative_Cleaned
							,	nbl.Narrative
							,	cc.MCCID
							--,	cc.LocationCountry
							--,	cc.OriginatorID
							,	cc.BrandID
							--,	CASE
							--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
							--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
							--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
							--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
							--	END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup nbl
							ON cc.BrandID = nbl.BrandID
							AND mnc.Narrative_Cleaned LIKE nbl.Narrative
						WHERE 1 = 1
						--AND mnc.MID = cc.MID
						--AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						--AND mnc.OriginatorID = cc.OriginatorID
						--AND (		mnc.OriginalNarrative = cc.Narrative
						--		OR	mnc.OriginalNarrative LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative
						--		OR	mnc.Narrative_Cleaned = cc.Narrative_Cleaned
						--		OR	mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned)
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.BrandID
								--,	cc.MID
								,	cc.Narrative_Cleaned
								,	nbl.Narrative
								,	cc.MCCID
								--,	cc.LocationCountry
								--,	cc.OriginatorID
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
						ORDER BY	(SELECT NULL)
								--,	CASE
								--		WHEN mnc.OriginalNarrative = cc.Narrative THEN 1
								--		WHEN mnc.OriginalNarrative LIKE cc.Narrative THEN 2
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative THEN 3
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative THEN 4
								--		WHEN mnc.Narrative_Cleaned = cc.Narrative_Cleaned THEN 5
								--		WHEN mnc.Narrative_Cleaned LIKE cc.Narrative_Cleaned THEN 6
								--	END
								,	COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

	/***********************************************************************************************************************
		6.15.	MID, MCCID
				Excluding Narrative, OriginatorID, Country
	***********************************************************************************************************************/
	
		--IF OBJECT_ID('tempdb..#SharedMIDs') IS NOT NULL DROP TABLE #SharedMIDs;
		--WITH
		--CurveCard AS (	SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE '%PP%*%'
		--				OR c.Narrative LIKE 'CURVE*%'),

		--PayPal AS (		SELECT	MID
		--					,	MCCID
		--				 FROM #Combinations c
		--				WHERE c.Narrative LIKE 'CRV*%'
		--				OR c.Narrative LIKE '%PayPal%*%'
		--				OR BrandID = 943),

		--iZettle AS (	SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'iz*%'
		--				OR BrandID = 1293),

		--Facebook AS (	SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'FBPAY%'),

		--LayBuy AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'LAYBUY%'),

		--NYA AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'NYA%'),

		--DMN AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'DMN%'),

		--Ritual AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'RITUAL-%'),

		--SQ AS (			SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'SQ%*%'),

		--SUMUP AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'SUMUP%'),

		--CAPITA AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'CAPITA%'),

		--GOFUNDME AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'GOFUNDME%'),

		--RH AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'RH%'),

		--TipJar AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'TipJar%'),

		--Fresha AS (		SELECT	MID
		--					,	MCCID
		--				FROM #Combinations c
		--				WHERE c.Narrative LIKE 'Fresha%'),

		--MultipleByMID AS (	SELECT	MID
		--						,	MCCID
		--					FROM #Combinations c
		--					GROUP BY	MID
		--							,	MCCID
		--					HAVING COUNT(DISTINCT BrandID) > 5),

		--Combined AS (	SELECT	MID
		--					,	MCCID
		--				FROM CurveCard
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM PayPal
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM iZettle
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM Facebook
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM LayBuy
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM NYA
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM DMN
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM Ritual
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM SQ
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM SUMUP
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM CAPITA
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM GOFUNDME
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM RH
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM TipJar
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM Fresha
		--				UNION ALL
		--				SELECT	MID
		--					,	MCCID
		--				FROM MultipleByMID)

		--SELECT	MID
		--	,	MCCID
		--INTO #SharedMIDs
		--FROM Combined
		--UNION
		--SELECT	MID
		--	,	MCCID
		--FROM #Combinations c
		--WHERE EXISTS (SELECT 1
		--			  FROM Combined cu
		--			  WHERE c.MID = cu.MID)

		--CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #SharedMIDs (MID, MCCID)

		--IF OBJECT_ID('tempdb..#MCCMID') IS NOT NULL DROP TABLE #MCCMID;
		--SELECT	mnc.ID
		--	,	mnc.MID
		--	,	mnc.OriginalNarrative
		--	,	mnc.Narrative_Cleaned
		--	,	mnc.LocationCountry
		--	,	mnc.MCCID
		--	,	x.BrandID
		--	,	x.BrandName
		--	,	x.Matches
		--	,	fm.MatchRatio
		--	,	ROW_NUMBER() OVER (PARTITION BY mnc.ID ORDER BY x.Matches DESC, fm.MatchRatio) AS MatchRank
		--INTO #MCCMID
		--FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		--CROSS APPLY (	SELECT	cc.MID
		--					,	cc.MCCID
		--					,	cc.BrandID
		--					,	br.BrandName
		--					,	COUNT(*) AS Matches
		--				FROM #Combinations cc
		--				INNER JOIN [Warehouse].[Relational].[Brand] br
		--					ON cc.BrandID = br.BrandID	
		--				WHERE mnc.MCCID = cc.MCCID
		--				AND mnc.MID = cc.MID
		--				GROUP BY	cc.MID
		--						,	cc.MCCID
		--						,	cc.BrandID
		--						,	br.BrandName) x
		--OUTER APPLY [dbo].[FuzzyMatch_iTVF2k5](mnc.Narrative_Cleaned, x.BrandName) fm
		--WHERE NOT EXISTS (	SELECT 1
		--					FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] p
		--					WHERE p.ComboID = mnc.ID)
		--AND NOT EXISTS (	SELECT 1
		--					FROM #SharedMIDs sm
		--					WHERE mnc.MID = sm.MID)

		--DELETE
		--FROM #MCCMID
		--WHERE MatchRank > 1


		--INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
		--														,	SuggestedBrandID
		--														,	MatchTypeID)
		--SELECT	DISTINCT 
		--		mnc.ID
		--	,	mm.BrandID
		--	,	15 as MatchTypeID
		--FROM #MCCMID mm
		--INNER JOIN [MIDI].[CTLoad_MIDINewCombo] mnc
		--	ON mm.ID = mnc.ID

	/***********************************************************************************************************************
		6.16.	Narrative Lookup ONLY
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID
																,	NarrativeMatchedOn)
		SELECT	DISTINCT 
				mnc.ID
			,	nbl.BrandID
			,	16 as MatchTypeID
			,	nbl.Narrative
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP (1)
								nbl.BrandID
							,	nbl.Narrative
							,	CASE
									WHEN mnc.OriginalNarrative = nbl.Narrative THEN 1
									WHEN mnc.OriginalNarrative LIKE nbl.Narrative THEN 2
									WHEN mnc.Narrative_Cleaned = nbl.Narrative THEN 3
									WHEN mnc.Narrative_Cleaned LIKE nbl.Narrative THEN 4
								END AS MatchOrder
							,	COUNT(*) AS Matches
						FROM #NarrativeBrandLookup nbl
						WHERE mnc.OriginalNarrative = nbl.Narrative
						OR	mnc.OriginalNarrative LIKE nbl.Narrative
						OR	mnc.Narrative_Cleaned = nbl.Narrative
						OR	mnc.Narrative_Cleaned LIKE nbl.Narrative
						GROUP BY	nbl.BrandID
								,	CASE
										WHEN mnc.OriginalNarrative = nbl.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE nbl.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = nbl.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE nbl.Narrative THEN 4
									END
								,	nbl.Narrative
						ORDER BY	CASE
										WHEN mnc.OriginalNarrative = nbl.Narrative THEN 1
										WHEN mnc.OriginalNarrative LIKE nbl.Narrative THEN 2
										WHEN mnc.Narrative_Cleaned = nbl.Narrative THEN 3
										WHEN mnc.Narrative_Cleaned LIKE nbl.Narrative THEN 4
									END
								,	COUNT(*)) nbl
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

/*******************************************************************************************************************************************
	7.	Update the suggested brand ID with the results of the preivous step
*******************************************************************************************************************************************/
		
	UPDATE mnc
	SET OriginalBrandID = pb.SuggestedBrandID
	,	MatchType = pb.MatchTypeID
	,	BrandProbability = pb.BrandProbability
	FROM [MIDI].[CTLoad_MIDINewCombo] mnc
	CROSS APPLY (	SELECT	TOP (1)
							ID
						,	ComboID
						,	SuggestedBrandID
						,	MatchTypeID
						,	BrandProbability
						,	MatchTypeID AS MinMatchTypeID
					FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
					WHERE mnc.ID = pb.ComboID
					ORDER BY pb.MatchTypeID) pb
	WHERE mnc.OriginalBrandID IS NULL
	

/*******************************************************************************************************************************************
	8.	Mark the rest as unbranded
*******************************************************************************************************************************************/

	UPDATE [MIDI].[CTLoad_MIDINewCombo]
	SET	OriginalBrandID = 944
	,	MatchType = 17
	WHERE OriginalBrandID IS NULL


/*******************************************************************************************************************************************
	9.	Mark known Narrative prefixes as the PSPs they belong to
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		9.1.	Mark paypal
	***********************************************************************************************************************/

		UPDATE [MIDI].[CTLoad_MIDINewCombo] 
		SET	OriginalBrandID = 943
		,	MatchType = 18
		WHERE (	OriginalNarrative LIKE '%PAYPAL%'
			OR	OriginalNarrative LIKE 'PP*%')
		AND (OriginalBrandID = 944)

	
	/***********************************************************************************************************************
		9.2.	Mark iZettle
	***********************************************************************************************************************/

		UPDATE [MIDI].[CTLoad_MIDINewCombo]
		SET	OriginalBrandID = 1293
		,	MatchType = 19
		WHERE OriginalNarrative Like '%IZ *%'
		AND (OriginalBrandID = 944)
	

/*******************************************************************************************************************************************
	10.	Where they are known cases where a Brand is assigned based on the above rules that is incorrect, change that brand to correct brand
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		10.1.	Swtich BrandID base on known MCC examples
	***********************************************************************************************************************/

		UPDATE mnc
		SET OriginalBrandID = mc.BrandIDChange
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		INNER JOIN [MIDI].[MIDIBrandChange_MCC] mc
			ON mnc.OriginalBrandID = mc.BrandIDInitial
			AND mnc.MCCID = mc.MCCID
			

	/***********************************************************************************************************************
		10.2.	Swtich BrandID base on known Narrative examples
	***********************************************************************************************************************/

		UPDATE mnc
		SET OriginalBrandID = mc.BrandIDChange
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		INNER JOIN [MIDI].[MIDIBrandChange_Narrative] mc
			ON mnc.OriginalBrandID = mc.BrandIDInitial
			AND mnc.Narrative_Cleaned LIKE mc.Narrative

	
/*******************************************************************************************************************************************
	11.	Various updates
*******************************************************************************************************************************************/

	DECLARE @TransactionStartDate DATE = DATEADD(MONTH, -12, GETDATE())

	IF OBJECT_ID('tempdb..#Combinations_All') IS NOT NULL DROP TABLE #Combinations_All
	SELECT	cc.BrandID
		,	br.BrandName
		,	cc.MID
		,	cc.Narrative
		,	Narrative_Cleaned = cc.Narrative
		,	cc.LocationCountry
		,	cc.MCCID
		,	cc.OriginatorID
		,	cc.IsHighVariance
		,	SUM(cc.Transactions) AS Transactions
		,	SUM(cc.Amount) AS Amount
	INTO #Combinations_All
	FROM (	SELECT	BrandID
				,	MID
				,	Narrative
				,	LocationCountry
				,	MCCID
				,	OriginatorID
				,	IsHighVariance
				,	SUM(1) AS Transactions
				,	SUM(Amount) AS Amount
			FROM [Warehouse].[Relational].[ConsumerCombination] cc
			INNER JOIN [Warehouse].[Relational].[ConsumerTransaction] ct
				ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
				AND @TransactionStartDate <= ct.TranDate
			WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
			GROUP BY	BrandID
					,	MID
					,	Narrative
					,	LocationCountry
					,	MCCID
					,	OriginatorID
					,	IsHighVariance
			UNION ALL
			SELECT	BrandID
				,	MID
				,	Narrative
				,	LocationCountry
				,	MCCID
				,	OriginatorID
				,	IsHighVariance
				,	SUM(1) AS Transactions
				,	SUM(Amount) AS Amount
			FROM [Warehouse].[Relational].[ConsumerCombination] cc
			INNER JOIN [Warehouse].[Relational].[ConsumerTransaction_CreditCard] ct
				ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
				AND @TransactionStartDate <= ct.TranDate
			WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
			GROUP BY	BrandID
					,	MID
					,	Narrative
					,	LocationCountry
					,	MCCID
					,	OriginatorID
					,	IsHighVariance
			UNION ALL
			SELECT	BrandID
				,	MID
				,	Narrative
				,	LocationCountry
				,	MCCID
				,	NULL AS OriginatorID
				,	IsHighVariance
				,	SUM(1) AS Transactions
				,	SUM(Amount) AS Amount
			FROM [WH_Virgin].[Trans].[ConsumerCombination] cc
			INNER JOIN [WH_Virgin].[Trans].[ConsumerTransaction] ct
				ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
				AND @TransactionStartDate <= ct.TranDate
			WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
			GROUP BY	BrandID
					,	MID
					,	Narrative
					,	LocationCountry
					,	MCCID
				--	,	OriginatorID
					,	IsHighVariance
			UNION ALL
			SELECT	BrandID
				,	MID
				,	Narrative
				,	LocationCountry
				,	MCCID
				,	OriginatorID
				,	IsHighVariance
				,	SUM(1) AS Transactions
				,	SUM(Amount) AS Amount
			FROM [WH_Visa].[Trans].[ConsumerCombination] cc
			INNER JOIN [WH_Visa].[Trans].[ConsumerTransaction] ct
				ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
				AND @TransactionStartDate <= ct.TranDate
			WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
			GROUP BY	BrandID
					,	MID
					,	Narrative
					,	LocationCountry
					,	MCCID
					,	OriginatorID
					,	IsHighVariance) cc
	LEFT JOIN [Warehouse].[Relational].[Brand] br
		ON cc.BrandID = br.BrandID
	GROUP BY	cc.BrandID
			,	br.BrandName
			,	cc.MID
			,	cc.Narrative
			,	cc.LocationCountry
			,	cc.MCCID
			,	cc.OriginatorID
			,	cc.IsHighVariance

	UPDATE c
	SET	Narrative_Cleaned = ISNULL(x.Narrative_Cleaned, c.Narrative)
	FROM #Combinations_All c -- 90,605
	OUTER APPLY dbo.iTVF_NarrativeCleaner(-1,c.Narrative) q1
	OUTER APPLY dbo.iTVF_NarrativeCleaner(q1.ID,q1.Narrative_Cleaned) q2
	OUTER APPLY dbo.iTVF_NarrativeCleaner(q2.ID,q2.Narrative_Cleaned) q3
	CROSS APPLY (SELECT	Narrative_Cleaned = COALESCE(q3.Narrative_Cleaned, q2.Narrative_Cleaned, q1.Narrative_Cleaned, c.Narrative_Cleaned)) x

	CREATE NONCLUSTERED INDEX [ix_Stuff3] ON #Combinations_All ([LocationCountry] ASC, [MCCID] ASC, [MID] ASC, [Narrative] ASC)
	CREATE NONCLUSTERED INDEX [ix_Stuff4] ON #Combinations_All ([MID] ASC,[LocationCountry] ASC,[MCCID] ASC) INCLUDE([Narrative])
	CREATE NONCLUSTERED INDEX [ix_Stuff5] ON #Combinations_All ([BrandID] ASC) INCLUDE([MID],[MCCID])
	CREATE NONCLUSTERED INDEX [ix_Stuff6] ON #Combinations_All ([MID] ASC, [MCCID] ASC) INCLUDE([BrandID])

	CREATE CLUSTERED INDEX CIX_MID ON #Combinations_All (MID)

	CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #Combinations_All (BrandID, MID, Narrative, LocationCountry, MCCID)


	DECLARE @MCC_SpendThreshold FLOAT = 0.05

	IF OBJECT_ID('tempdb..#MCCs') IS NOT NULL DROP TABLE #MCCs
	;WITH
	MCCIDs AS (	SELECT	BrandID
		    		,	BrandName
					,	MCCID
		    		,	Transactions
					,	Amount
					,	SUM(Amount) OVER (PARTITION BY BrandID) AS Amount_BrandID
				FROM (	SELECT	BrandID
							,	BrandName
							,	MCCID
							,	SUM(Transactions) AS Transactions
							,	SUM(ABS(Amount)) AS Amount
						FROM #Combinations_All
						GROUP BY	BrandID
								,	BrandName
								,	MCCID) c),
	
	MCCIDRanked AS (SELECT	m.BrandID
						,	m.MCCID
						,	RANK() OVER (PARTITION BY BrandID ORDER BY Amount DESC, Transactions DESC) AS RankMCC
					FROM MCCIDs m
					INNER JOIN [Warehouse].[Relational].[MCCList] mcc
						ON m.MCCID = mcc.MCCID
					WHERE Amount_BrandID * @MCC_SpendThreshold <= Amount),

	MMCCIDRanked_Pivot AS (	SELECT	BrandID
								,	MAX(CASE WHEN RankMCC = 1 THEN MCCID ELSE '' END) AS MostCommonMCCID
								,	MAX(CASE WHEN RankMCC = 2 THEN MCCID ELSE '' END) AS SecondMostCommonMCCID
								,	MAX(CASE WHEN RankMCC = 3 THEN MCCID ELSE '' END) AS ThirdMostCommonMCCID
							FROM MCCIDRanked
							GROUP BY BrandID)

	SELECT	mcc.BrandID
		,	COALESCE(mcc.MostCommonMCCID, '') AS MostCommonMCCID
		,	COALESCE(mcc.SecondMostCommonMCCID, '') AS SecondMostCommonMCCID
		,	COALESCE(mcc.ThirdMostCommonMCCID, '') AS ThirdMostCommonMCCID
	INTO #MCCs
	FROM MMCCIDRanked_Pivot mcc;

	UPDATE mnc
	SET	mnc.OriginalBrand_FirstMostCommonMCCID = COALESCE(mcc.MostCommonMCCID, '')
	,	mnc.OriginalBrand_SecondMostCommonMCCID = COALESCE(mcc.SecondMostCommonMCCID, '')
	,	mnc.OriginalBrand_ThirdMostCommonMCCID = COALESCE(mcc.ThirdMostCommonMCCID, '')
	FROM [MIDI].[CTLoad_MIDINewCombo] mnc
	LEFT JOIN #MCCs mcc
		ON mnc.OriginalBrandID = mcc.BrandID

	UPDATE [MIDI].[CTLoad_MIDINewCombo]
	SET DoMCCsMatch =	CASE
							WHEN MCCID IN (OriginalBrand_FirstMostCommonMCCID,	OriginalBrand_SecondMostCommonMCCID, OriginalBrand_ThirdMostCommonMCCID) THEN 1
							ELSE 0
						END


	IF OBJECT_ID('tempdb..#CombinedCombinationsTemp') IS NOT NULL DROP TABLE #CombinedCombinationsTemp
	SELECT	MID
		,	LocationCountry
		,	MCCID
		,	Narrative
		,	Narrative_Cleaned
		,	BrandID
		,	LEN(Narrative_Cleaned) AS Narrative_CleanedLength
	INTO #CombinedCombinationsTemp
	FROM (	SELECT	MID
				,	LocationCountry
				,	MCCID
				,	Narrative
				,	Narrative_Cleaned
				,	BrandID
			FROM #Combinations_All
			UNION ALL
			SELECT	MID
				,	LocationCountry
				,	MCCID
				,	OriginalNarrative
				,	Narrative_Cleaned
				,	OriginalBrandID
			FROM [MIDI].[CTLoad_MIDINewCombo]) c

	;WITH
	Updater AS (SELECT	MID
					,	LocationCountry
					,	MCCID
					,	Narrative_CleanedLength
					,	AVG(Narrative_CleanedLength) OVER (PARTITION BY MID, LocationCountry, MCCID) AS Narrative_CleanedLength_Avg
				FROM #CombinedCombinationsTemp)

	UPDATE Updater
	SET Narrative_CleanedLength = Narrative_CleanedLength_Avg;

	CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #CombinedCombinationsTemp (MID, LocationCountry, MCCID, Narrative, Narrative_Cleaned, BrandID, Narrative_CleanedLength)

	IF OBJECT_ID('tempdb..#CombinedCombinations') IS NOT NULL DROP TABLE #CombinedCombinations
	SELECT	DISTINCT
			MID
		,	LocationCountry
		,	MCCID
		,	Narrative
		,	Narrative_Cleaned
		,	BrandID
		,	Narrative_CleanedLength
		,	CONVERT(INT, NULL) AS NarrativeCount
		,	CONVERT(INT, NULL) AS NarrativeCount_PartialLeft
		,	CONVERT(INT, NULL) AS NarrativeCount_PartialRight
	INTO #CombinedCombinations
	FROM #CombinedCombinationsTemp c

	;WITH
	Updater AS (SELECT	MID
					,	LocationCountry
					,	MCCID
					,	NarrativeCount
					,	NarrativeCount_PartialLeft
					,	NarrativeCount_PartialRight
					,	COUNT(*) OVER (PARTITION BY MID, LocationCountry, MCCID) AS NarrativeCount_New
					,	COUNT(*) OVER (PARTITION BY LEFT(Narrative_Cleaned, Narrative_CleanedLength * 0.25), MID, LocationCountry, MCCID) AS NarrativeCount_PartialLeft_New
					,	COUNT(*) OVER (PARTITION BY RIGHT(Narrative_Cleaned, Narrative_CleanedLength * 0.25), MID, LocationCountry, MCCID) AS NarrativeCount_PartialRight_New
				FROM #CombinedCombinations)

	UPDATE Updater
	SET NarrativeCount = NarrativeCount_New
	,	NarrativeCount_PartialLeft = NarrativeCount_PartialLeft_New
	,	NarrativeCount_PartialRight = NarrativeCount_PartialRight_New;


	IF OBJECT_ID('tempdb..#EntriesPerCombination') IS NOT NULL DROP TABLE #EntriesPerCombination
	SELECT	MID
		,	LocationCountry
		,	MCCID
		,	NarrativeCount
		,	MAX(NarrativeCount_PartialLeft) AS NarrativeCount_PartialLeft
		,	MAX(NarrativeCount_PartialRight) AS NarrativeCount_PartialRight
		,	COUNT(DISTINCT BrandID) AS BrandCount
	INTO #EntriesPerCombination
	FROM #CombinedCombinations
	GROUP BY	MID
			,	LocationCountry
			,	MCCID
			,	NarrativeCount


	UPDATE mnc
	SET	mnc.NarrativeCount = COALESCE(epc.NarrativeCount, 0)
	,	mnc.NarrativeCount_PartialLeft = COALESCE(epc.NarrativeCount_PartialLeft, 0)
	,	mnc.NarrativeCount_PartialRight = COALESCE(epc.NarrativeCount_PartialRight, 0)
	,	mnc.BrandCount = COALESCE(epc.BrandCount, 0)
	FROM [MIDI].[CTLoad_MIDINewCombo] mnc
	LEFT JOIN #EntriesPerCombination epc
		ON mnc.MID = epc.MID
		AND mnc.MCCID = epc.MCCID
		AND mnc.LocationCountry = epc.LocationCountry







		


	IF OBJECT_ID('tempdb..#ProbabilityCorrectMatch_BrandID_MCCID') IS NOT NULL DROP TABLE #ProbabilityCorrectMatch_BrandID_MCCID
	SELECT	bsc.MatchTypeID
		,	bsc.MatchType
		,	mnc.DoMCCsMatch
		,	mnc.OriginalBrandID
		,	mnc.MCCID
		,	COUNT(CASE WHEN mnc.OriginalBrandID = mnc.UpdatedBrandID THEN 1 END) * 1.0 / COUNT(*) AS CorrectMatches
	INTO #ProbabilityCorrectMatch_BrandID_MCCID
	FROM [MIDI].[CTLoad_MIDINewCombo_Log] mnc
	INNER JOIN [MIDI].[CTLoad_BrandSuggestConfidence] bsc
		ON mnc.MatchType = bsc.MatchTypeID
	GROUP BY	bsc.MatchTypeID
			,	bsc.MatchType
			,	mnc.DoMCCsMatch
			,	mnc.OriginalBrandID
			,	mnc.MCCID
	ORDER BY	bsc.MatchTypeID
			,	bsc.MatchType
			,	mnc.DoMCCsMatch
			,	mnc.OriginalBrandID

	IF OBJECT_ID('tempdb..#ProbabilityCorrectMatch_BrandID') IS NOT NULL DROP TABLE #ProbabilityCorrectMatch_BrandID
	SELECT	bsc.MatchTypeID
		,	bsc.MatchType
		,	mnc.DoMCCsMatch
		,	mnc.OriginalBrandID
		,	COUNT(CASE WHEN mnc.OriginalBrandID = mnc.UpdatedBrandID THEN 1 END) * 1.0 / COUNT(*) AS CorrectMatches
	INTO #ProbabilityCorrectMatch_BrandID
	FROM [MIDI].[CTLoad_MIDINewCombo_Log] mnc
	INNER JOIN [MIDI].[CTLoad_BrandSuggestConfidence] bsc
		ON mnc.MatchType = bsc.MatchTypeID
	GROUP BY	bsc.MatchTypeID
			,	bsc.MatchType
			,	mnc.DoMCCsMatch
			,	mnc.OriginalBrandID
	ORDER BY	bsc.MatchTypeID
			,	bsc.MatchType
			,	mnc.DoMCCsMatch
			,	mnc.OriginalBrandID

	IF OBJECT_ID('tempdb..#ProbabilityCorrectMatch_MCCID') IS NOT NULL DROP TABLE #ProbabilityCorrectMatch_MCCID
	SELECT	bsc.MatchTypeID
		,	bsc.MatchType
		,	mnc.DoMCCsMatch
		,	mnc.MCCID
		,	COUNT(CASE WHEN mnc.OriginalBrandID = mnc.UpdatedBrandID THEN 1 END) * 1.0 / COUNT(*) AS CorrectMatches
	INTO #ProbabilityCorrectMatch_MCCID
	FROM [MIDI].[CTLoad_MIDINewCombo_Log] mnc
	INNER JOIN [MIDI].[CTLoad_BrandSuggestConfidence] bsc
		ON mnc.MatchType = bsc.MatchTypeID
	GROUP BY	bsc.MatchTypeID
			,	bsc.MatchType
			,	mnc.DoMCCsMatch
			,	mnc.MCCID
	ORDER BY	bsc.MatchTypeID
			,	bsc.MatchType
			,	mnc.DoMCCsMatch
			,	mnc.MCCID

	IF OBJECT_ID('tempdb..#ProbabilityCorrectMatch') IS NOT NULL DROP TABLE #ProbabilityCorrectMatch
	SELECT	bsc.MatchTypeID
		,	bsc.MatchType
		,	mnc.DoMCCsMatch
		,	COUNT(CASE WHEN mnc.OriginalBrandID = mnc.UpdatedBrandID THEN 1 END) * 1.0 / COUNT(*) AS CorrectMatches
	INTO #ProbabilityCorrectMatch
	FROM [MIDI].[CTLoad_MIDINewCombo_Log] mnc
	INNER JOIN [MIDI].[CTLoad_BrandSuggestConfidence] bsc
		ON mnc.MatchType = bsc.MatchTypeID
	GROUP BY	bsc.MatchTypeID
			,	bsc.MatchType
			,	mnc.DoMCCsMatch
	ORDER BY	bsc.MatchTypeID
			,	bsc.MatchType
			,	mnc.DoMCCsMatch

	UPDATE mnc
	SET mnc.BrandProbability = CONVERT(DECIMAL(19,4), pcm.CorrectMatches)
	FROM #ProbabilityCorrectMatch_BrandID_MCCID pcm
	INNER JOIN [MIDI].[CTLoad_MIDINewCombo] mnc
		ON pcm.OriginalBrandID = mnc.OriginalBrandID
		AND pcm.MCCID = mnc.MCCID
		AND pcm.DoMCCsMatch = mnc.DoMCCsMatch
		AND pcm.MatchTypeID = mnc.MatchType
	WHERE BrandProbability IS NULL

	UPDATE mnc
	SET mnc.BrandProbability = CONVERT(DECIMAL(19,4), pcm.CorrectMatches)
	FROM #ProbabilityCorrectMatch_BrandID pcm
	INNER JOIN [MIDI].[CTLoad_MIDINewCombo] mnc
		ON pcm.OriginalBrandID = mnc.OriginalBrandID
		AND pcm.DoMCCsMatch = mnc.DoMCCsMatch
		AND pcm.MatchTypeID = mnc.MatchType
	WHERE BrandProbability IS NULL

	UPDATE mnc
	SET mnc.BrandProbability = CONVERT(DECIMAL(19,4), pcm.CorrectMatches)
	FROM #ProbabilityCorrectMatch_MCCID pcm
	INNER JOIN [MIDI].[CTLoad_MIDINewCombo] mnc
		ON pcm.MCCID = mnc.MCCID
		AND pcm.DoMCCsMatch = mnc.DoMCCsMatch
		AND pcm.MatchTypeID = mnc.MatchType
	WHERE BrandProbability IS NULL

	UPDATE mnc
	SET mnc.BrandProbability = CONVERT(DECIMAL(19,4), pcm.CorrectMatches)
	FROM #ProbabilityCorrectMatch pcm
	INNER JOIN [MIDI].[CTLoad_MIDINewCombo] mnc
		ON pcm.DoMCCsMatch = mnc.DoMCCsMatch
		AND pcm.MatchTypeID = mnc.MatchType
	WHERE BrandProbability IS NULL



RETURN 0