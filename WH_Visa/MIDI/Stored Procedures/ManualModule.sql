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

	SELECT @RowsAffected = COUNT(*) FROM [MIDI].[CTLoad_MIDIHolding] cis
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
											,	MatchCount)
	SELECT	MID
		,	MerchantName
		,	MerchantCountry
		,	MCCID
		,	MerchantAcquirerBin
		,	COUNT(*)
	FROM [MIDI].[CTLoad_MIDIHolding] mh
	WHERE ConsumerCombinationID IS NULL
	AND MerchantName IS NOT NULL
	AND MCCID IS NOT NULL
	GROUP BY	MID
			,	MerchantName
			,	MerchantCountry
			,	MCCID
			,	MerchantAcquirerBin
	ORDER BY	MerchantName
			,	MerchantCountry
			,	MCCID
			,	MID
			,	MerchantAcquirerBin

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
	OUTER APPLY dbo.iTVF_NarrativeCleaner(-1,mnc.OriginalNarrative) q1
	OUTER APPLY dbo.iTVF_NarrativeCleaner(q1.ID,q1.Narrative_Cleaned) q2
	OUTER APPLY dbo.iTVF_NarrativeCleaner(q2.ID,q2.Narrative_Cleaned) q3
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
			,	LocationCountry
			,	MCCID
			,	CONVERT(INT, OriginatorID) AS OriginatorID
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
			,	LocationCountry
			,	MCCID
			,	CONVERT(INT, OriginatorID) AS OriginatorID
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
			,	LocationCountry
			,	MCCID
			,	CONVERT(INT, OriginatorID) AS OriginatorID
		FROM [Trans].[ConsumerCombination] cc
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND EXISTS (SELECT 1
					FROM [Trans].[ConsumerTransaction] ct
					WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID
					AND @LastYear <= ct.TranDate)
		
		SET @RowsAffected = @@ROWCOUNT

		CREATE NONCLUSTERED INDEX [ix_Stuff3] ON #Combinations ([LocationCountry] ASC, [MCCID] ASC, [OriginatorID] ASC, [MID] ASC, [Narrative] ASC)
		CREATE NONCLUSTERED INDEX [ix_Stuff4] ON #Combinations ([MID] ASC,[LocationCountry] ASC,[MCCID] ASC, [OriginatorID] ASC) INCLUDE([Narrative])
		CREATE NONCLUSTERED INDEX [ix_Stuff5] ON #Combinations ([BrandID] ASC) INCLUDE([MID],[MCCID],[OriginatorID])
		CREATE NONCLUSTERED INDEX [ix_Stuff6] ON #Combinations ([MID] ASC, [MCCID] ASC, [OriginatorID] ASC) INCLUDE([BrandID])

		CREATE CLUSTERED INDEX CIX_MID ON #Combinations (MID)

		CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #Combinations (BrandID, MID, Narrative, LocationCountry, MCCID, [OriginatorID])
	
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Store Combinations [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
		
		IF OBJECT_ID('tempdb..#NarrativeBrandLookup') IS NOT NULL DROP TABLE #NarrativeBrandLookup
		SELECT	BrandID
			,	Narrative
		INTO #NarrativeBrandLookup
		FROM [WH_Visa].[MIDI].[BrandMatch]
		WHERE BrandID != 944
		UNION
		SELECT	BrandID
			,	Narrative
		FROM [WH_Virgin].[MIDI].[BrandMatch]
		WHERE BrandID != 944
		UNION
		SELECT	BrandID
			,	Narrative
		FROM [Warehouse].[Staging].[BrandMatch]
		WHERE BrandID != 944
		
		SET @RowsAffected = @@ROWCOUNT

		CREATE CLUSTERED INDEX CIX_All ON #NarrativeBrandLookup (BrandID, Narrative)
		CREATE NONCLUSTERED INDEX IX_BrandID ON #NarrativeBrandLookup (BrandID)
		CREATE NONCLUSTERED INDEX IX_Narrative ON #NarrativeBrandLookup (Narrative)
	
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Store Lookups [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

/*******************************************************************************************************************************************
	6.	Run through various scenarios to suggest a BrandID in dreasing probability of a correct match
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		6.1.	Narrative, MID, MCC, Country
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	1 as MatchTypeID
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								cc.MID
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						WHERE mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND mnc.OriginalNarrative = cc.Narrative
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.MID
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.BrandID
						ORDER BY COUNT(*) DESC) cc

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative, MID, MCC, Country [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


	/***********************************************************************************************************************
		6.2.	Narrative Lookup, MID, MCC, Country
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	2 as MatchTypeID
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								cc.MID
							,	cc.MCCID
							,	cc.LocationCountry
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup bm 
							ON mnc.Narrative_Cleaned LIKE bm.Narrative
							AND bm.BrandID = cc.BrandID
						WHERE mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.MID
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.BrandID
						ORDER BY COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative Lookup, MID, MCC, Country [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		6.3.	Narrative Lookup, MID, Country
	***********************************************************************************************************************/
	
		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	3 as MatchTypeID
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								cc.MID
							,	cc.LocationCountry
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup bm 
							ON mnc.Narrative_Cleaned LIKE bm.Narrative
							AND bm.BrandID = cc.BrandID
						WHERE mnc.MID = cc.MID
						AND mnc.LocationCountry = cc.LocationCountry
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.MID
								,	cc.LocationCountry
								,	cc.BrandID
						ORDER BY COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative Lookup, MID, Country [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		6.4.	Narrative Lookup, MCC, Country
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	4 as MatchTypeID
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								cc.MCCID
							,	cc.LocationCountry
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup bm 
							ON mnc.Narrative_Cleaned LIKE bm.Narrative
							AND bm.BrandID = cc.BrandID
						WHERE mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.MCCID
								,	cc.LocationCountry
								,	cc.BrandID
						ORDER BY COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative Lookup, MCC, Country [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


	/***********************************************************************************************************************
		6.5.	Narrative Lookup, MID
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	5 as MatchTypeID
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								cc.MID
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup bm 
							ON mnc.Narrative_Cleaned LIKE bm.Narrative
							AND bm.BrandID = cc.BrandID
						WHERE mnc.MID = cc.MID
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.MID
								,	cc.BrandID
						ORDER BY COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative Lookup, MID [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		6.6.	Narrative Lookup, MCC
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID)
		SELECT	DISTINCT 
				mnc.ID
			,	cc.BrandID
			,	6 as MatchTypeID
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	TOP 1
								cc.MCCID
							,	cc.BrandID
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN #NarrativeBrandLookup bm 
							ON mnc.Narrative_Cleaned LIKE bm.Narrative
							AND bm.BrandID = cc.BrandID
						WHERE mnc.MCCID = cc.MCCID
						AND cc.BrandID NOT IN (944, 943, 1293)
						GROUP BY	cc.MCCID
								,	cc.BrandID
						ORDER BY COUNT(*) DESC) cc
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative Lookup, MCC [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		6.7.	MID, MCC
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#SharedMIDs') IS NOT NULL DROP TABLE #SharedMIDs;
		WITH
		CurveCard AS (	SELECT	MID
							,	MCCID
						FROM #Combinations c
						WHERE c.Narrative LIKE '%PP%*%'
						OR c.Narrative LIKE 'CURVE*%'),

		PayPal AS (		SELECT	MID
							,	MCCID
						 FROM #Combinations c
						WHERE c.Narrative LIKE 'CRV*%'
						OR c.Narrative LIKE '%PayPal%*%'
						OR BrandID = 943),

		iZettle AS (	SELECT	MID
							,	MCCID
						FROM #Combinations c
						WHERE c.Narrative LIKE 'iz*%'
						OR BrandID = 1293),

		Facebook AS (	SELECT	MID
							,	MCCID
						FROM #Combinations c
						WHERE c.Narrative LIKE 'FBPAY%'),

		LayBuy AS (		SELECT	MID
							,	MCCID
						FROM #Combinations c
						WHERE c.Narrative LIKE 'LAYBUY%'),

		NYA AS (		SELECT	MID
							,	MCCID
						FROM #Combinations c
						WHERE c.Narrative LIKE 'NYA%'),

		DMN AS (		SELECT	MID
							,	MCCID
						FROM #Combinations c
						WHERE c.Narrative LIKE 'DMN%'),

		Ritual AS (		SELECT	MID
							,	MCCID
						FROM #Combinations c
						WHERE c.Narrative LIKE 'RITUAL-%'),

		SQ AS (			SELECT	MID
							,	MCCID
						FROM #Combinations c
						WHERE c.Narrative LIKE 'SQ%*%'),

		SUMUP AS (		SELECT	MID
							,	MCCID
						FROM #Combinations c
						WHERE c.Narrative LIKE 'SUMUP%'),

		MultipleByMID AS (	SELECT	MID
								,	MCCID
							FROM #Combinations c
							GROUP BY	MID
									,	MCCID
							HAVING COUNT(DISTINCT BrandID) > 5),

		Combined AS (	SELECT	MID
							,	MCCID
						FROM CurveCard
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM PayPal
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM iZettle
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM Facebook
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM LayBuy
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM NYA
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM DMN
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM Ritual
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM SQ
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM SUMUP
						UNION ALL
						SELECT	MID
							,	MCCID
						FROM MultipleByMID)

		SELECT	MID
			,	MCCID
		INTO #SharedMIDs
		FROM Combined
		UNION
		SELECT	MID
			,	MCCID
		FROM #Combinations c
		WHERE EXISTS (SELECT 1
					  FROM Combined cu
					  WHERE c.MID = cu.MID)

		CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #SharedMIDs (MID, MCCID)

		IF OBJECT_ID('tempdb..#MCCMID') IS NOT NULL DROP TABLE #MCCMID;
		SELECT	mnc.ID
			,	mnc.MID
			,	mnc.OriginalNarrative
			,	mnc.Narrative_Cleaned
			,	mnc.LocationCountry
			,	mnc.MCCID
			,	x.BrandID
			,	x.BrandName
			,	x.Matches
			,	fm.MatchRatio
			,	ROW_NUMBER() OVER (PARTITION BY mnc.ID ORDER BY x.Matches DESC, fm.MatchRatio) AS MatchRank
		INTO #MCCMID
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS APPLY (	SELECT	cc.MID
							,	cc.MCCID
							,	Narrative_Cleaned
							,	cc.LocationCountry
							,	cc.BrandID
							,	br.BrandName
							,	COUNT(*) AS Matches
						FROM #Combinations cc
						INNER JOIN [Warehouse].[Relational].[Brand] br
							ON cc.BrandID = br.BrandID	
						WHERE mnc.MCCID = cc.MCCID
						AND mnc.MID = cc.MID
						GROUP BY	cc.MID
								,	cc.MCCID
								,	cc.LocationCountry
								,	cc.BrandID
								,	br.BrandName) x
		OUTER APPLY [dbo].[FuzzyMatch_iTVF2k5](mnc.Narrative_Cleaned, x.BrandName) fm
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] p
							WHERE p.ComboID = mnc.ID)
		AND NOT EXISTS (	SELECT 1
							FROM #SharedMIDs sm
							WHERE mnc.MID = sm.MID
							AND mnc.MCCID = sm.MCCID)

		DELETE
		FROM #MCCMID
		WHERE MatchRank > 1


		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID)
		SELECT	DISTINCT 
				mnc.ID
			,	mm.BrandID
			,	7 as MatchTypeID
		FROM #MCCMID mm
		INNER JOIN [MIDI].[CTLoad_MIDINewCombo] mnc
			ON mm.ID = mnc.ID

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - MID, MCC [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		6.8.	Narrative Lookup ONLY
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (	ComboID
																,	SuggestedBrandID
																,	MatchTypeID)
		SELECT	DISTINCT 
				mnc.ID
			,	bm.BrandID
			,	8 as MatchTypeID
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		INNER JOIN #NarrativeBrandLookup bm 
			On mnc.Narrative_Cleaned Like bm.Narrative
		WHERE NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb
							WHERE mnc.ID = pb.ComboID)

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative ONLY [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		6.9.	Narrative Fuzzy Match
	***********************************************************************************************************************/

	/*

		IF OBJECT_ID('tempdb..#FuzzyMatch') IS NOT NULL DROP TABLE #FuzzyMatch;
		SELECT	mnc.ID
			,	mnc.MID
			,	mnc.Narrative
			,	mnc.Narrative_Cleaned
			,	mnc.LocationCountry
			,	mnc.MCCID
			,	cc.BrandID
			,	cc.Narrative AS NarrativeMatched
			,	fm.MatchRatio
			,	ROW_NUMBER() OVER (PARTITION BY mnc.ID ORDER BY fm.MatchRatio) AS MatchRank
		INTO #FuzzyMatch
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		CROSS JOIN #Combinations cc
		OUTER APPLY [dbo].[FuzzyMatch_iTVF2k5](mnc.Narrative, cc.Narrative) fm
		WHERE mnc.LocationCountry = cc.LocationCountry
		AND mnc.MCCID = cc.MCCID
		AND NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] p
							WHERE p.ComboID = mnc.ID)
		AND fm.MatchRatio > 0
		AND 1 = 2


		DECLARE @ID INT
			,	@MaxID INT

		SELECT	@ID = MIN(ID)
			,	@MaxID = MAX(ID)
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		WHERE EXISTS (	SELECT 1
						FROM #Combinations cc
						WHERE mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID)
		AND NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] p
							WHERE p.ComboID = mnc.ID)

		SELECT COUNT(*)
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		WHERE EXISTS (	SELECT 1
						FROM #Combinations cc
						WHERE mnc.LocationCountry = cc.LocationCountry
						AND mnc.MCCID = cc.MCCID)
		AND NOT EXISTS (	SELECT 1
							FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] p
							WHERE p.ComboID = mnc.ID)

		SELECT @ID

		WHILE @ID < @MaxID
			BEGIN
				INSERT INTO #FuzzyMatch
				SELECT	mnc.ID
					,	mnc.MID
					,	mnc.Narrative
					,	mnc.Narrative_Cleaned
					,	mnc.LocationCountry
					,	mnc.MCCID
					,	cc.BrandID
					,	cc.Narrative AS NarrativeMatched
					,	fm.MatchRatio
					,	ROW_NUMBER() OVER (PARTITION BY mnc.ID ORDER BY fm.MatchRatio DESC) AS MatchRank
				FROM [MIDI].[CTLoad_MIDINewCombo] mnc
				CROSS JOIN #Combinations cc
				OUTER APPLY [dbo].[FuzzyMatch_iTVF2k5](mnc.Narrative_Cleaned, cc.Narrative) fm
				WHERE mnc.LocationCountry = cc.LocationCountry
				AND mnc.MCCID = cc.MCCID
				AND mnc.ID = @ID
				AND fm.MatchRatio > 0

				SELECT	@ID = MIN(ID)
				FROM [MIDI].[CTLoad_MIDINewCombo] mnc
				WHERE EXISTS (	SELECT 1
								FROM #Combinations cc
								WHERE mnc.LocationCountry = cc.LocationCountry
								AND mnc.MCCID = cc.MCCID)
				AND NOT EXISTS (	SELECT 1
									FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] p
									WHERE p.ComboID = mnc.ID)
				AND @ID < ID
			END

			15:29


		SELECT COUNT(DISTINCT ID)
		FROM #FuzzyMatch

		CREATE CLUSTERED INDEX CIX_ID ON #FuzzyMatch (ID, BrandID)

		SELECT	DISTINCT
				fm.ID
			,	fm.MID
			,	fm.Narrative
			,	fm.Narrative_Cleaned
			,	fm.LocationCountry
			,	fm.MCCID
			,	fm.BrandID
			,	fm.NarrativeMatched
			,	fm.MatchRatio
			,	fm.MatchRank
			,	br.BrandName
		FROM #FuzzyMatch fm
		INNER JOIN Warehouse.Relational.Brand br
			ON fm.BrandID = br.BrandID
		WHERE Warehouse.[Prototype].[DamLev](fm.Narrative_Cleaned, fm.NarrativeMatched, 100) < 5
		ORDER BY	fm.ID
				,	fm.MatchRatio DESC

		SELECT	*
			,	Warehouse.[Prototype].[DamLev](Narrative, Narrative_Cleaned, 100)
		FROM MIDI.CTLoad_MIDINewCombo

		*/
		
		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative Fuzzy Match [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

/*******************************************************************************************************************************************
	7.	Update the suggested brand ID with the results of the preivous step
*******************************************************************************************************************************************/
		
	UPDATE mnc
	SET OriginalBrandID = pbm.SuggestedBrandID
	,	MatchType = pbm.MatchTypeID
	,	BrandProbability = pbm.BrandProbability
	FROM [MIDI].[CTLoad_MIDINewCombo] mnc
	INNER JOIN (SELECT	ID
					,	ComboID
					,	SuggestedBrandID
					,	MatchTypeID
					,	BrandProbability
					,	MIN(MatchTypeID) OVER (PARTITION BY ComboID) AS MinMatchTypeID
				FROM [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] pb) pbm
		ON mnc.ID = pbm.ComboID
	WHERE MatchTypeID = MinMatchTypeID 
	AND mnc.OriginalBrandID IS NULL

	SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Update BrandIDs [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	

/*******************************************************************************************************************************************
	8.	Mark the rest as unbranded
*******************************************************************************************************************************************/

	UPDATE [MIDI].[CTLoad_MIDINewCombo]
	SET	OriginalBrandID = 944
	,	MatchType = 10
	WHERE OriginalBrandID IS NULL

	SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Mark remaining unbranded [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	

/*******************************************************************************************************************************************
	9.	Mark known Narrative prefixes as the PSPs they belong to
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		9.1.	Mark paypal
	***********************************************************************************************************************/

		UPDATE [MIDI].[CTLoad_MIDINewCombo] 
		SET	OriginalBrandID = 943
		,	MatchType = 11
		WHERE (	OriginalNarrative LIKE '%PAYPAL%'
			OR	OriginalNarrative LIKE 'PP*%')
		AND (OriginalBrandID = 944 OR MatchType = 9)

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Mark PayPal [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		9.2.	Mark iZettle
	***********************************************************************************************************************/

		UPDATE [MIDI].[CTLoad_MIDINewCombo]
		SET	OriginalBrandID = 1293
		,	MatchType = 12
		WHERE OriginalNarrative Like '%IZ *%'
		AND (OriginalBrandID = 944 OR MatchType = 9)

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Mark iZettle [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	

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

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - MCC BrandID Change [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


	/***********************************************************************************************************************
		10.2.	Swtich BrandID base on known Narrative examples
	***********************************************************************************************************************/

		UPDATE mnc
		SET OriginalBrandID = mc.BrandIDChange
		FROM [MIDI].[CTLoad_MIDINewCombo] mnc
		INNER JOIN [MIDI].[MIDIBrandChange_Narrative] mc
			ON mnc.OriginalBrandID = mc.BrandIDInitial
			AND mnc.Narrative_Cleaned LIKE mc.Narrative

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative BrandID Change [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
		
	
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
		,	cc.IsHighVariance
		,	SUM(cc.Transactions) AS Transactions
		,	SUM(cc.Amount) AS Amount
	INTO #Combinations_All
	FROM (	SELECT	BrandID
				,	MID
				,	Narrative
				,	LocationCountry
				,	MCCID
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
					,	IsHighVariance
			UNION ALL
			SELECT	BrandID
				,	MID
				,	Narrative
				,	LocationCountry
				,	MCCID
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
					,	IsHighVariance
			UNION ALL
			SELECT	BrandID
				,	MID
				,	Narrative
				,	LocationCountry
				,	MCCID
				,	IsHighVariance
				,	SUM(1) AS Transactions
				,	SUM(Amount) AS Amount
			FROM [Trans].[ConsumerCombination] cc
			INNER JOIN [Trans].[ConsumerTransaction] ct
				ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
				AND @TransactionStartDate <= ct.TranDate
			WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
			GROUP BY	BrandID
					,	MID
					,	Narrative
					,	LocationCountry
					,	MCCID
					,	IsHighVariance) cc
	LEFT JOIN [Warehouse].[Relational].[Brand] br
		ON cc.BrandID = br.BrandID
	GROUP BY	cc.BrandID
			,	br.BrandName
			,	cc.MID
			,	cc.Narrative
			,	cc.LocationCountry
			,	cc.MCCID
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
