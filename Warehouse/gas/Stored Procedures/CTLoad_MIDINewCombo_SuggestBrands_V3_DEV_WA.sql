
-- =============================================
-- Author:		JEA
-- Create date: 16/04/2014
-- Description:	Clears new combo table for repopulation

-- Change log:	RF 2018-10-25
--				Step aadded at the beggining of the process to clean narratives, remvoving prefixes
--				for portable payment machines such as iZettle allowing for better matches on narratives
--				and reduction of false positives
--				Conditions to match at each step updated for query effiency and reduction of false postivie matches

-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_SuggestBrands_V3_DEV_WA]

AS
BEGIN

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF OBJECT_ID('tempdb..#CC_Narrative') IS NOT NULL DROP TABLE #CC_Narrative
	SELECT DISTINCT
		   cc.Narrative
	INTO #CC_Narrative
	FROM [Relational].[ConsumerCombination] cc
	WHERE cc.BrandID != 944

	CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_Narrative ON #CC_Narrative (Narrative)

	IF OBJECT_ID('tempdb..#CC_NarrativeCleaned') IS NOT NULL DROP TABLE #CC_NarrativeCleaned
	SELECT cc.Narrative
		 , LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(cc.Narrative, ' ', '<>'), '><', ''), '<>', ' '))) AS NarrativeCleaned
		 , 0 AS IsPrefixRemoved
	INTO #CC_NarrativeCleaned
	FROM #CC_Narrative cc

	CREATE NONCLUSTERED INDEX IX_NarrativeCleaned ON #CC_NarrativeCleaned (NarrativeCleaned)

	IF OBJECT_ID('tempdb..#MNC_NarrativeCleaned') IS NOT NULL DROP TABLE #MNC_NarrativeCleaned
	SELECT mnc.ID AS MIDINewComboID
		 , LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(mnc.Narrative, ' ', '<>'), '><', ''), '<>', ' '))) AS NarrativeCleaned
		 , 0 AS IsPrefixRemoved
	INTO #MNC_NarrativeCleaned
	FROM [Staging].[CTLoad_MIDINewCombo_v2] mnc

	CREATE NONCLUSTERED INDEX IX_NarrativeCleaned ON #MNC_NarrativeCleaned (NarrativeCleaned)

	DECLARE @LoopNumber INT = (SELECT Min(ID) FROM [Staging].[CTLoad_MIDINarrativeCleanup] WHERE LiveRule = 1)
		  , @LoopEnd INT = (SELECT Max(ID) FROM [Staging].[CTLoad_MIDINarrativeCleanup] WHERE LiveRule = 1)
		  , @TextToReplace VARCHAR(15)
		  , @TextToReplace_NoSpaces VARCHAR(15)
		  , @TextToReplaceJoin VARCHAR(15)
		  , @TextToReplaceJoin_NoSpaces VARCHAR(15)
		  , @NarrativeNotLike VARCHAR(15)
		  , @IsPrefixRemoved BIT

	While @LoopNumber <= @LoopEnd
		Begin

			SELECT @TextToReplace = REPLACE(TextToReplace, '%', '')
				 , @TextToReplacejoin = TextToReplace
				 , @TextToReplace_NoSpaces = REPLACE(REPLACE(TextToReplace, '%', ''), ' ', '')
				 , @TextToReplacejoin_NoSpaces = REPLACE(TextToReplace, ' ', '')
				 , @NarrativeNotLike = NarrativeNotLike
				 , @IsPrefixRemoved = IsPrefixRemoved
			FROM Warehouse.Staging.CTLoad_MIDINarrativeCleanup
			WHERE ID = @LoopNumber
			

			UPDATE nc
			SET NarrativeCleaned = nc_2.Narrative_Cleaned
			  , IsPrefixRemoved = @IsPrefixRemoved
			FROM #MNC_NarrativeCleaned nc
			CROSS APPLY (SELECT CASE
									WHEN (NarrativeCleaned LIKE @TextToReplacejoin OR NarrativeCleaned LIKE @TextToReplacejoin_NoSpaces) AND NarrativeCleaned NOT LIKE @NarrativeNotLike
											THEN LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(NarrativeCleaned, @TextToReplace, ''), @TextToReplace_NoSpaces, ''), ' ', '<>'), '><', ''), '<>', ' ')))
									ELSE NarrativeCleaned
								END AS Narrative_Cleaned) nc_1
			CROSS APPLY (SELECT CASE
									WHEN LEFT(nc_1.Narrative_Cleaned, 1) IN ('-', '*') 
											THEN LTRIM(RIGHT(nc_1.Narrative_Cleaned, LEN(nc_1.Narrative_Cleaned) - 1))
									Else nc_1.Narrative_Cleaned
								END AS Narrative_Cleaned) nc_2
			WHERE (nc.NarrativeCleaned LIKE @TextToReplacejoin OR nc.NarrativeCleaned LIKE @TextToReplacejoin_NoSpaces)
			AND nc.NarrativeCleaned NOT LIKE @NarrativeNotLike

			UPDATE nc
			SET NarrativeCleaned = nc_2.Narrative_Cleaned
			  , IsPrefixRemoved = @IsPrefixRemoved
			FROM #MNC_NarrativeCleaned nc
			CROSS APPLY (SELECT CASE
									WHEN (NarrativeCleaned LIKE @TextToReplacejoin OR NarrativeCleaned LIKE @TextToReplacejoin_NoSpaces) AND NarrativeCleaned NOT LIKE @NarrativeNotLike
											Then LTrim(RTrim(Replace(Replace(Replace(Replace(Replace(NarrativeCleaned, @TextToReplace, ''), @TextToReplace_NoSpaces, ''), ' ', '<>'), '><', ''), '<>', ' ')))
									Else NarrativeCleaned
								End AS Narrative_Cleaned) nc_1
			CROSS APPLY (SELECT CASE
									WHEN Left(nc_1.Narrative_Cleaned, 1) IN ('-', '*') 
											Then Ltrim(Right(nc_1.Narrative_Cleaned, Len(nc_1.Narrative_Cleaned) - 1))
									Else nc_1.Narrative_Cleaned
								End AS Narrative_Cleaned) nc_2
			WHERE (nc.NarrativeCleaned LIKE @TextToReplacejoin OR nc.NarrativeCleaned LIKE @TextToReplacejoin_NoSpaces)
			AND nc.NarrativeCleaned NOT LIKE @NarrativeNotLike

			SELECT @LoopNumber = Min(ID)
			FROM Warehouse.Staging.CTLoad_MIDINarrativeCleanup
			WHERE ID > @LoopNumber
			AND LiveRule = 1

		END

	IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
	SELECT DISTINCT 
		   cc.*
		 , nc.NarrativeCleaned
		 , nc.IsPrefixRemoved
	INTO #ConsumerCombination
	FROM [Relational].[ConsumerCombination] cc
	INNER JOIN #CC_NarrativeCleaned nc
		ON cc.Narrative = nc.Narrative
	WHERE cc.BrandID != 944

	UPDATE mnc
	SET mnc.Narrative_Cleaned = nc.NarrativeCleaned
	  , mnc.IsPrefixRemoved = nc.IsPrefixRemoved
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN #MNC_NarrativeCleaned nc
		on mnc.ID = nc.MIDINewComboID


	--Narratve, MID, MCC, Country, Originator

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp1') IS NOT NULL DROP TABLE #PossibleBrandsTemp1
		SELECT m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
			 , LEN(bm.Narrative) AS MatchedONLength
			 , MAX(LEN(bm.Narrative)) OVER (PARTITION BY m.ID) AS MaxMatchedONLengthPerID
		INTO #PossibleBrandsTemp1
		FROM [Staging].[CTLoad_MIDINewCombo_v2] m
		INNER JOIN [Staging].[BrandMatch] bm 
			ON m.Narrative_Cleaned LIKE BM.Narrative
		WHERE LEN(MID) > 0
		AND NOT EXISTS (SELECT 1
						FROM [Staging].[CTLoad_MIDINewCombo_PossibleBrands] p
						WHERE p.ComboID = m.ID)
		
		DELETE pbt
		FROM #PossibleBrandsTemp1 pbt
		WHERE MatchedONLength < MaxMatchedONLengthPerID
		
		CREATE CLUSTERED INDEX CIX_CC ON #PossibleBrandsTemp1 (BrandID, MID, LocationCountry, MCCID, OriginatorID)
		 
		INSERT INTO [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (ComboID
																  , SuggestedBrandID
																  , MatchTypeID)
		SELECT DISTINCT
			   pbt.MIDINewCombo
			 , pbt.BrandID
			 , 1 as MatchTypeID
		FROM #PossibleBrandsTemp1 pbt
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[ConsumerCombination] cc
						WHERE pbt.MID = cc.MID
						AND pbt.LocationCountry = cc.LocationCountry
						AND pbt.MCCID = cc.MCCID
						AND pbt.OriginatorID = cc.OriginatorID
						AND cc.PaymentGatewayStatusID != 1) --exclude non-individuated paypal

	--Narrative, MID, Country, Originator

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp2') IS NOT NULL DROP TABLE #PossibleBrandsTemp2
		SELECT m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
			 , LEN(bm.Narrative) AS MatchedONLength
			 , MAX(LEN(bm.Narrative)) OVER (PARTITION BY m.ID) AS MaxMatchedONLengthPerID
		INTO #PossibleBrandsTemp2
		FROM [Staging].[CTLoad_MIDINewCombo_v2] m
		INNER JOIN [Staging].[BrandMatch] bm 
			ON m.Narrative_Cleaned LIKE BM.Narrative
		WHERE LEN(MID) > 0
		AND NOT EXISTS (SELECT 1
						FROM [Staging].[CTLoad_MIDINewCombo_PossibleBrands] p
						WHERE p.ComboID = m.ID)
		
		DELETE pbt
		FROM #PossibleBrandsTemp2 pbt
		WHERE MatchedONLength < MaxMatchedONLengthPerID
						
		INSERT INTO [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (ComboID
																  , SuggestedBrandID
																  , MatchTypeID)
		SELECT DISTINCT
			   pbt.MIDINewCombo
			 , pbt.BrandID
			 , 2 as MatchTypeID
		FROM #PossibleBrandsTemp2 pbt
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[ConsumerCombination] cc
						WHERE pbt.MID = cc.MID
						AND pbt.LocationCountry = cc.LocationCountry
						AND pbt.OriginatorID = cc.OriginatorID
						AND cc.PaymentGatewayStatusID != 1) --exclude non-individuated paypal


	--Narrative, MCC, Country, Originator

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp3') IS NOT NULL DROP TABLE #PossibleBrandsTemp3
		SELECT m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
			 , LEN(bm.Narrative) AS MatchedONLength
			 , MAX(LEN(bm.Narrative)) OVER (PARTITION BY m.ID) AS MaxMatchedONLengthPerID
		INTO #PossibleBrandsTemp3
		FROM [Staging].[CTLoad_MIDINewCombo_v2] m
		INNER JOIN [Staging].[BrandMatch] bm 
			ON m.Narrative_Cleaned LIKE BM.Narrative
		WHERE LEN(MID) > 0
		AND NOT EXISTS (SELECT 1
						FROM [Staging].[CTLoad_MIDINewCombo_PossibleBrands] p
						WHERE p.ComboID = m.ID)
		
		DELETE pbt
		FROM #PossibleBrandsTemp3 pbt
		WHERE MatchedONLength < MaxMatchedONLengthPerID
		 
		INSERT INTO [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (ComboID
																  , SuggestedBrandID
																  , MatchTypeID)
		SELECT DISTINCT
			   pbt.MIDINewCombo
			 , pbt.BrandID
			 , 3 as MatchTypeID
		FROM #PossibleBrandsTemp3 pbt
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[ConsumerCombination] cc
						WHERE pbt.LocationCountry = cc.LocationCountry
						AND pbt.MCCID = cc.MCCID
						AND pbt.OriginatorID = cc.OriginatorID
						AND cc.PaymentGatewayStatusID != 1) --exclude non-individuated paypal


	--Narrative, MID, MCC, Country

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp4') IS NOT NULL DROP TABLE #PossibleBrandsTemp4
		SELECT m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
			 , LEN(bm.Narrative) AS MatchedONLength
			 , MAX(LEN(bm.Narrative)) OVER (PARTITION BY m.ID) AS MaxMatchedONLengthPerID
		INTO #PossibleBrandsTemp4
		FROM [Staging].[CTLoad_MIDINewCombo_v2] m
		INNER JOIN [Staging].[BrandMatch] bm 
			ON m.Narrative_Cleaned LIKE BM.Narrative
		WHERE LEN(MID) > 0
		AND NOT EXISTS (SELECT 1
						FROM [Staging].[CTLoad_MIDINewCombo_PossibleBrands] p
						WHERE p.ComboID = m.ID)
		
		DELETE pbt
		FROM #PossibleBrandsTemp4 pbt
		WHERE MatchedONLength < MaxMatchedONLengthPerID
		 
		INSERT INTO [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (ComboID
																  , SuggestedBrandID
																  , MatchTypeID)
		SELECT DISTINCT
			   pbt.MIDINewCombo
			 , pbt.BrandID
			 , 4 as MatchTypeID
		FROM #PossibleBrandsTemp4 pbt
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[ConsumerCombination] cc
						WHERE pbt.MID = cc.MID
						AND pbt.LocationCountry = cc.LocationCountry
						AND pbt.MCCID = cc.MCCID
						AND cc.PaymentGatewayStatusID != 1) --exclude non-individuated paypal


	--Narrative, MCC, Country

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp5') IS NOT NULL DROP TABLE #PossibleBrandsTemp5
		SELECT m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
			 , LEN(bm.Narrative) AS MatchedONLength
			 , MAX(LEN(bm.Narrative)) OVER (PARTITION BY m.ID) AS MaxMatchedONLengthPerID
		INTO #PossibleBrandsTemp5
		FROM [Staging].[CTLoad_MIDINewCombo_v2] m
		INNER JOIN [Staging].[BrandMatch] bm 
			ON m.Narrative_Cleaned LIKE BM.Narrative
		WHERE LEN(MID) > 0
		AND NOT EXISTS (SELECT 1
						FROM [Staging].[CTLoad_MIDINewCombo_PossibleBrands] p
						WHERE p.ComboID = m.ID)
		
		DELETE pbt
		FROM #PossibleBrandsTemp5 pbt
		WHERE MatchedONLength < MaxMatchedONLengthPerID
		 
		INSERT INTO [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (ComboID
																  , SuggestedBrandID
																  , MatchTypeID)
		SELECT DISTINCT
			   pbt.MIDINewCombo
			 , pbt.BrandID
			 , 5 as MatchTypeID
		FROM #PossibleBrandsTemp5 pbt
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[ConsumerCombination] cc
						WHERE pbt.LocationCountry = cc.LocationCountry
						AND pbt.MCCID = cc.MCCID
						AND cc.PaymentGatewayStatusID != 1) --exclude non-individuated paypal


	--Narrative, MID, Country

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp6') IS NOT NULL DROP TABLE #PossibleBrandsTemp6
		SELECT m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
			 , LEN(bm.Narrative) AS MatchedONLength
			 , MAX(LEN(bm.Narrative)) OVER (PARTITION BY m.ID) AS MaxMatchedONLengthPerID
		INTO #PossibleBrandsTemp6
		FROM [Staging].[CTLoad_MIDINewCombo_v2] m
		INNER JOIN [Staging].[BrandMatch] bm 
			ON m.Narrative_Cleaned LIKE BM.Narrative
		WHERE LEN(MID) > 0
		AND NOT EXISTS (SELECT 1
						FROM [Staging].[CTLoad_MIDINewCombo_PossibleBrands] p
						WHERE p.ComboID = m.ID)
		
		DELETE pbt
		FROM #PossibleBrandsTemp6 pbt
		WHERE MatchedONLength < MaxMatchedONLengthPerID
		 
		INSERT INTO [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (ComboID
																  , SuggestedBrandID
																  , MatchTypeID)
		SELECT DISTINCT
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 6 as MatchTypeID
		FROM #PossibleBrandsTemp6 pbt
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[ConsumerCombination] cc
						WHERE pbt.MID = cc.MID
						AND pbt.LocationCountry = cc.LocationCountry
						AND cc.PaymentGatewayStatusID != 1) --exclude non-individuated paypal

		
	--Narrative, MCC

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp7') IS NOT NULL DROP TABLE #PossibleBrandsTemp7
		SELECT m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
			 , LEN(bm.Narrative) AS MatchedONLength
			 , MAX(LEN(bm.Narrative)) OVER (PARTITION BY m.ID) AS MaxMatchedONLengthPerID
		INTO #PossibleBrandsTemp7
		FROM [Staging].[CTLoad_MIDINewCombo_v2] m
		INNER JOIN [Staging].[BrandMatch] bm 
			ON m.Narrative_Cleaned LIKE BM.Narrative
		WHERE LEN(MID) > 0
		AND NOT EXISTS (SELECT 1
						FROM [Staging].[CTLoad_MIDINewCombo_PossibleBrands] p
						WHERE p.ComboID = m.ID)
		
		DELETE pbt
		FROM #PossibleBrandsTemp7 pbt
		WHERE MatchedONLength < MaxMatchedONLengthPerID
		 
		INSERT INTO [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (ComboID
																  , SuggestedBrandID
																  , MatchTypeID)
		SELECT DISTINCT
			   pbt.MIDINewCombo
			 , pbt.BrandID
			 , 7 as MatchTypeID
		FROM #PossibleBrandsTemp7 pbt
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[ConsumerCombination] cc
						WHERE pbt.MCCID = cc.MCCID
						AND cc.PaymentGatewayStatusID != 1) --exclude non-individuated paypal
		
		
	--MID, MCC

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp8') IS NOT NULL DROP TABLE #PossibleBrandsTemp8
		SELECT m.ID as MIDINewCombo
			 , m.MID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
		INTO #PossibleBrandsTemp8
		FROM [Staging].[CTLoad_MIDINewCombo_v2] m
		WHERE NOT EXISTS (	SELECT 1
							FROM [Staging].[CTLoad_MIDINewCombo_PossibleBrands] p
							WHERE p.ComboID = m.ID)

		CREATE CLUSTERED INDEX CIX_SharedMIDs_MIDMCCID ON #PossibleBrandsTemp8 (MID, MCCID)


		SELECT *
		FROM #PossibleBrandsTemp8


		IF OBJECT_ID('tempdb..#SharedMIDs') IS NOT NULL DROP TABLE #SharedMIDs
		SELECT DISTINCT 
			   MID
			 , MCCID
		INTO #SharedMIDs
		FROM [Relational].[ConsumerCombination] cc
		WHERE BrandID in (1293, 943, 944)
		UNION
		SELECT DISTINCT 
			   MID
			 , MCCID
		FROM [Relational].[ConsumerCombination] cc
		WHERE Narrative LIKE '%CRV%*%'
		UNION
		SELECT DISTINCT 
			   MID
			 , MCCID
		FROM [Relational].[ConsumerCombination] cc
		WHERE Narrative LIKE '%PP%*%'
		UNION
		SELECT DISTINCT 
			   MID
			 , MCCID
		FROM [Relational].[ConsumerCombination] cc
		WHERE Narrative LIKE '%PayPal%*%'

		CREATE CLUSTERED INDEX CIX_SharedMIDs_MIDMCCID ON #SharedMIDs (MID, MCCID)
		
		IF OBJECT_ID('tempdb..#MIDsMultipleBrands') IS NOT NULL DROP TABLE #MIDsMultipleBrands
		SELECT cc.MID
			 , cc.MCCID
			 , COUNT(DISTINCT BrandID) as BrandIDs
		INTO #MIDsMultipleBrands
		FROM [Relational].[ConsumerCombination] cc
		WHERE NOT EXISTS (SELECT 1
						  FROM #SharedMIDs sm
						  WHERE cc.MID = sm.MID
						  AND cc.MCCID = sm.MCCID)
		GROUP BY cc.MID
			   , cc.MCCID
		
		CREATE CLUSTERED INDEX CIX_MIDsMultipleBrands_MIDMCCID ON #MIDsMultipleBrands (MID, MCCID)

		

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp8_2') IS NOT NULL DROP TABLE #PossibleBrandsTemp8_2
		SELECT	pbt.MIDINewCombo
			,	pbt.Narrative_Cleaned
			,	cc.BrandID
			,	br.BrandName
		INTO #PossibleBrandsTemp8_2
		FROM #PossibleBrandsTemp8 pbt
		INNER JOIN [Relational].[ConsumerCombination] cc
			ON pbt.MCCID = cc.MCCID
			AND pbt.MID = cc.MID
		INNER JOIN Warehouse.Relational.Brand br
			on cc.BrandID = br.BrandID
		WHERE EXISTS (	SELECT 1
						FROM #MIDsMultipleBrands mmb
						WHERE pbt.MID = mmb.MID
						AND pbt.MCCID = mmb.MCCID)
		AND cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
		And Len(pbt.MID) > 0
		AND cc.BrandID not in (944, 943)
		
		INSERT INTO [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (ComboID
																  , SuggestedBrandID
																  , MatchTypeID)
		SELECT DISTINCT
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 8 as MatchTypeID
		FROM #PossibleBrandsTemp8_2 pbt
		WHERE Case When pbt.BrandID = 1224 And Narrative_Cleaned Not Like '%sl%w%' Then 1 End Is Null
		And (	((Narrative_Cleaned Like '%' + Left(BrandName, 1) + '%' Or BrandName Like '%' + Left(Narrative_Cleaned, 2) + '%'))
		Or		((Narrative_Cleaned Like '%' + Left(BrandName, 2) + '%' Or BrandName Like '%' + Left(Narrative_Cleaned, 3) + '%')))


	--Prefix ONLY

		IF OBJECT_ID('tempdb..#PossibleBrandsTemp9') IS NOT NULL DROP TABLE #PossibleBrandsTemp9
		SELECT m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
			 , LEN(bm.Narrative) AS MatchedONLength
			 , MAX(LEN(bm.Narrative)) OVER (PARTITION BY m.ID) AS MaxMatchedONLengthPerID
		INTO #PossibleBrandsTemp9
		FROM [Staging].[CTLoad_MIDINewCombo_v2] m
		INNER JOIN [Staging].[BrandMatch] bm 
			ON m.Narrative_Cleaned LIKE BM.Narrative
		WHERE LEN(MID) > 0
		AND NOT EXISTS (SELECT 1
						FROM [Staging].[CTLoad_MIDINewCombo_PossibleBrands] p
						WHERE p.ComboID = m.ID)
		
		DELETE pbt
		FROM #PossibleBrandsTemp9 pbt
		WHERE MatchedONLength < MaxMatchedONLengthPerID
		 
		INSERT INTO [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		SELECT DISTINCT
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 9 as MatchTypeID
		FROM #PossibleBrandsTemp9 pbt
		

	----LOAD TEXT MATCHES
	--INSERT INTO Staging.CTLoad_MIDINewCombo_BrandMatch(ComboID, BrandMatchID, BrandID, BrandGroupID)
	--SELECT DISTINCT M.ID, BM.BrandMatchID, BM.BrandID, B.BrandGroupID
	--FROM Staging.CTLoad_MIDINewCombo M
	--INNER JOIN Staging.BrandMatch bm ON M.Narrative LIKE BM.Narrative
	--INNER JOIN Relational.Brand b ON bm.BrandID = b.BrandID

	--UPDATE INFORMATION IN MATCH TABLE
	--EXEC gas.CTLoad_MIDINewCombo_UpdateMatchInfo_V2 (code added to the end of this sp instead)

	If Object_ID('tempdb..#CTLoad_MIDINewCombo_PossibleBrands_MinMatchType') Is Not Null Drop Table #CTLoad_MIDINewCombo_PossibleBrands_MinMatchType
	Select ID
		 , ComboID
		 , SuggestedBrandID
		 , MatchTypeID
		 , BrandProbability
	Into #CTLoad_MIDINewCombo_PossibleBrands_MinMatchType
	From (Select ID
			   , ComboID
			   , SuggestedBrandID
			   , MatchTypeID
			   , BrandProbability
			   , Min(MatchTypeID) Over (Partition by ComboID) as MinMatchTypeID
		  FROM Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands pb) mpb
	Where MatchTypeID = MinMatchTypeID

	UPDATE mnc
	SET SuggestedBrandID = pbm.SuggestedBrandID
	  , MatchType = pbm.MatchTypeID
	  , BrandProbability = pbm.BrandProbability
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN #CTLoad_MIDINewCombo_PossibleBrands_MinMatchType pbm
		ON mnc.ID = pbm.ComboID
	WHERE mnc.SuggestedBrandID IS NULL

	If Object_ID('tempdb..#CTLoad_MIDINewCombo_PossibleBrands_MatchCount') Is Not Null Drop Table #CTLoad_MIDINewCombo_PossibleBrands_MatchCount
	Select ComboID
		 , COUNT(1) AS MatchCount
	Into #CTLoad_MIDINewCombo_PossibleBrands_MatchCount
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands
	WHERE SuggestedBrandID != 943
	AND SuggestedBrandID != 944
	GROUP BY ComboID
	HAVING COUNT(1) > 1

	UPDATE mnc
	SET MatchCount = pbmc.MatchCount
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN #CTLoad_MIDINewCombo_PossibleBrands_MatchCount pbmc
		ON mnc.ID = pbmc.ComboID
	WHERE SuggestedBrandID != 943
	AND SuggestedBrandID != 944

	
	----Mark the rest as unbranded
	UPDATE mnc
	SET SuggestedBrandID = 944
	  , MatchType = 11
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	WHERE SuggestedBrandID IS NULL

	--match paypal
	UPDATE mnc
	SET SuggestedBrandID = 943
	  , MatchType = 10
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	WHERE (Narrative LIKE '%PAYPAL%') -- OR Narrative LIKE 'PP*%')
	AND (SuggestedBrandID = 944 Or MatchType = 9)

	--match iZettle
	UPDATE Warehouse.Staging.CTLoad_MIDINewCombo_v2
	SET SuggestedBrandID = 1293
	  , MatchType = 14
	WHERE Narrative Like '%IZ *%'
	AND (SuggestedBrandID = 944 Or MatchType = 9)

	--CHANGE SUGGESTED BRAND IDs ACCORDING TO EXCEPTIONS

	UPDATE mnc
	SET SuggestedBrandID = mc.BrandIDChange
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN Staging.MIDIBrandChange_MCC mc
		ON mnc.SuggestedBrandID = mc.BrandIDInitial
		AND mnc.MCCID = mc.MCCID

	UPDATE mnc
	SET SuggestedBrandID = mc.BrandIDChange
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN Staging.MIDIBrandChange_Narrative mc
		ON mnc.SuggestedBrandID = mc.BrandIDInitial
		AND mnc.Narrative_Cleaned LIKE mc.Narrative


END
