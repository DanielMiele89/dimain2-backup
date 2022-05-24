CREATE PROCEDURE [MIDI].[__Manual_Module_Archived]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT


--EXEC gas.CTLoad_BrandSuggestions_Clear
TRUNCATE TABLE MIDI.CTLoad_MIDINewCombo_Branded
TRUNCATE TABLE MIDI.CTLoad_MIDINewCombo_BrandMatch
TRUNCATE TABLE MIDI.CTLoad_MIDINewCombo_DataMining
TRUNCATE TABLE MIDI.CTLoad_MIDINewCombo_PossibleBrands
TRUNCATE TABLE MIDI.CTLoad_MIDINewCombo_V2
TRUNCATE TABLE MIDI.CreditCardLoad_MIDIHolding_Combos


SELECT @RowsAffected = COUNT(*) FROM MIDI.CTLoad_MIDIHolding cis
IF @RowsAffected = 0 BEGIN
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - No rows to process'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	RETURN 0
END
ELSE
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Starting manual module'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



--Load CTLoad_MIDINewCombo
--EXEC Staging.CTLoad_GetNewCombos -->> [Staging].[CTLoad_MIDINewCombo_v2] 
-- REQUIRES Get Acquirer script #####################################
INSERT INTO MIDI.CTLoad_MIDINewCombo_v2 (MID, Narrative, LocationCountry, MCCID, OriginatorID, IsCreditOrigin, AcquirerID) 
SELECT MID, Narrative, LocationCountry, MCCID, OriginatorID, CAST(0 AS BIT) AS IsCreditOrigin, 0 AS AcquirerID
FROM MIDI.CTLoad_MIDIHolding 
WHERE ConsumerCombinationID IS NULL
UNION ALL
SELECT MID, Narrative, LocationCountry, MCCID, OriginatorReference AS OriginatorID, CAST(1 AS BIT) AS IsCreditOrigin, 0 AS AcquirerID
FROM MIDI.CreditCardLoad_MIDIHolding 
WHERE ConsumerCombinationID IS NULL
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Collect rows to process [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


--EXEC MIDI.CTLoad_MIDINewCombo_SuggestBrands_V3
UPDATE mnc SET
	Narrative_Cleaned = ISNULL(x.Narrative_Cleaned,mnc.Narrative),
	mnc.IsPrefixRemoved = x.IsPrefixRemoved
FROM MIDI.CTLoad_MIDINewCombo_v2 mnc -- 90,605
OUTER APPLY dbo.iTVF_NarrativeCleaner(-1,mnc.Narrative) q1
OUTER APPLY dbo.iTVF_NarrativeCleaner(q1.ID,q1.Narrative_Cleaned) q2
OUTER APPLY dbo.iTVF_NarrativeCleaner(q2.ID,q2.Narrative_Cleaned) q3
CROSS APPLY (
	SELECT Narrative_Cleaned = COALESCE(q3.Narrative_Cleaned, q2.Narrative_Cleaned, q1.Narrative_Cleaned, mnc.Narrative_Cleaned),
		IsPrefixRemoved = COALESCE(q3.IsPrefixRemoved, q2.IsPrefixRemoved, q1.IsPrefixRemoved, mnc.IsPrefixRemoved)
) x
--WHERE mnc.Narrative <> x.Narrative_Cleaned 
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narrative cleaner [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
-- (573814 rows affected) / 00:00:21


----------------------------------------------------------------------------------------
--Prefix, MID, MCC, Country, Originator/Acquirer
----------------------------------------------------------------------------------------
INSERT INTO MIDI.CTLoad_MIDINewCombo_PossibleBrands (ComboID, SuggestedBrandID, MatchTypeID)
SELECT DISTINCT 
	m.ID, bm.BrandID, 1 as MatchTypeID
FROM MIDI.CTLoad_MIDINewCombo_v2 m
INNER JOIN MIDI.BrandMatch bm 
	ON m.Narrative_Cleaned LIKE BM.Narrative
INNER JOIN Trans.ConsumerCombination cc
	ON m.MID = cc.MID
	AND m.LocationCountry = cc.LocationCountry
	AND m.MCCID = cc.MCCID
LEFT JOIN MIDI.MOMCombinationAcquirer a
	ON m.AcquirerID = A.AcquirerID
	AND cc.ConsumerCombinationID = A.ConsumerCombinationID
WHERE m.OriginatorID != ''
	AND cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND (M.OriginatorID = cc.OriginatorID OR M.AcquirerID IS Not NULL)
	--AND Len(M.MID) > 0
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Prefix, MID, MCC, Country, Originator/Acquirer [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



----------------------------------------------------------------------------------------
--Prefix, MID, Country, Originator/Acquirer
----------------------------------------------------------------------------------------
INSERT INTO MIDI.CTLoad_MIDINewCombo_PossibleBrands (ComboID, SuggestedBrandID, MatchTypeID)
SELECT DISTINCT
	m.ID, bm.BrandID, 2 as MatchTypeID
FROM MIDI.CTLoad_MIDINewCombo_v2 m
INNER JOIN MIDI.BrandMatch bm 
	ON m.Narrative_Cleaned LIKE bm.Narrative
INNER JOIN Trans.ConsumerCombination cc
	ON m.MID = cc.MID
	And m.LocationCountry = cc.LocationCountry
LEFT JOIN MIDI.MOMCombinationAcquirer a
	ON m.AcquirerID = A.AcquirerID
	AND cc.ConsumerCombinationID = A.ConsumerCombinationID
WHERE m.OriginatorID != ''
	AND cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	And (m.OriginatorID = cc.OriginatorID OR a.AcquirerID IS Not NULL)
	--AND Len(m.MID) > 0
	AND NOT EXISTS (SELECT 1 FROM MIDI.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Prefix, MID, Country, Originator/Acquirer [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
						


----------------------------------------------------------------------------------------
--Prefix, MCC, Country, Originator/Acquirer
----------------------------------------------------------------------------------------
INSERT INTO MIDI.CTLoad_MIDINewCombo_PossibleBrands (ComboID, SuggestedBrandID, MatchTypeID)
SELECT DISTINCT
	m.ID, bm.BrandID, 3 as MatchTypeID
FROM MIDI.CTLoad_MIDINewCombo_v2 m
INNER JOIN MIDI.BrandMatch bm 
	ON m.Narrative_Cleaned LIKE BM.Narrative

INNER JOIN Trans.ConsumerCombination cc
	ON m.LocationCountry = cc.LocationCountry
	AND m.MCCID = cc.MCCID

LEFT JOIN MIDI.MOMCombinationAcquirer a
	ON m.AcquirerID = A.AcquirerID
	AND cc.ConsumerCombinationID = A.ConsumerCombinationID
WHERE m.OriginatorID != ''
	AND cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND (m.OriginatorID = cc.OriginatorID OR a.AcquirerID IS Not NULL)
	AND NOT EXISTS (SELECT 1 FROM MIDI.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Prefix, MCC, Country, Originator/Acquirer [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



----------------------------------------------------------------------------------------
--Prefix, MID, MCC, Country
----------------------------------------------------------------------------------------
INSERT INTO MIDI.CTLoad_MIDINewCombo_PossibleBrands (ComboID, SuggestedBrandID, MatchTypeID)
SELECT DISTINCT
	m.ID, bm.BrandID, 4 as MatchTypeID
FROM MIDI.CTLoad_MIDINewCombo_v2 m
INNER JOIN MIDI.BrandMatch bm 
	ON m.Narrative_Cleaned Like BM.Narrative
INNER JOIN Trans.ConsumerCombination cc
	ON m.LocationCountry = cc.LocationCountry
	AND m.MCCID = cc.MCCID
	AND m.MID = cc.MID
WHERE cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	--AND LEN(m.MID) > 0 
	AND NOT EXISTS (SELECT 1 FROM MIDI.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Prefix, MID, MCC, Country [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



----------------------------------------------------------------------------------------
--Prefix, MCC, Country
----------------------------------------------------------------------------------------
INSERT INTO MIDI.CTLoad_MIDINewCombo_PossibleBrands (ComboID, SuggestedBrandID, MatchTypeID)
SELECT DISTINCT
	m.ID, bm.BrandID, 5 as MatchTypeID
FROM MIDI.CTLoad_MIDINewCombo_v2 m
INNER JOIN MIDI.BrandMatch bm 
	ON m.Narrative_Cleaned LIKE BM.Narrative
INNER JOIN Trans.ConsumerCombination cc
	ON m.LocationCountry = cc.LocationCountry
	AND m.MCCID = cc.MCCID
WHERE cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND NOT EXISTS (SELECT 1 FROM MIDI.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Prefix, MCC, Country [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



----------------------------------------------------------------------------------------
--Prefix, MID, Country
----------------------------------------------------------------------------------------
INSERT INTO MIDI.CTLoad_MIDINewCombo_PossibleBrands (ComboID, SuggestedBrandID, MatchTypeID)
SELECT DISTINCT
	m.ID, bm.BrandID, 6 as MatchTypeID
FROM MIDI.CTLoad_MIDINewCombo_v2 m
INNER JOIN MIDI.BrandMatch bm 
	ON m.Narrative_Cleaned LIKE BM.Narrative
INNER JOIN Trans.ConsumerCombination cc
	ON m.LocationCountry = cc.LocationCountry
	AND m.MID = cc.MID
WHERE cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	--AND Len(m.MID) > 0 
	AND NOT EXISTS (SELECT 1 FROM MIDI.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Prefix, MID, Country [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


		
----------------------------------------------------------------------------------------
--Prefix, MCC
----------------------------------------------------------------------------------------
INSERT INTO MIDI.CTLoad_MIDINewCombo_PossibleBrands (ComboID, SuggestedBrandID, MatchTypeID)
SELECT DISTINCT
	m.ID, bm.BrandID, 7 as MatchTypeID
FROM MIDI.CTLoad_MIDINewCombo_v2 m
INNER JOIN MIDI.BrandMatch bm 
	ON m.Narrative_Cleaned LIKE BM.Narrative
INNER JOIN Trans.ConsumerCombination cc
	ON m.MCCID = cc.MCCID
WHERE cc.PaymentGatewayStatusID != 1 
	AND NOT EXISTS (SELECT 1 FROM MIDI.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Prefix, MCC [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



----------------------------------------------------------------------------------------
--MID, MCC
----------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
SELECT cc.MID, cc.MCCID, COUNT(*) as BrandIDs
INTO #ConsumerCombination
FROM Trans.ConsumerCombination cc
WHERE NOT EXISTS (
	SELECT 1
	FROM Trans.ConsumerCombination sm
	WHERE (sm.BrandID in (1293, 943, 944)
		Or sm.Narrative Like '%CRV%*%'
		Or sm.Narrative Like '%PP%*%'
		Or sm.Narrative Like '%PayPal%*%')
		AND cc.MID = sm.MID
		AND cc.MCCID = sm.MCCID
)
GROUP BY cc.MID, cc.MCCID
-- 931,820

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #ConsumerCombination (MID, MCCID)


INSERT INTO midi.CTLoad_MIDINewCombo_PossibleBrands (ComboID, SuggestedBrandID, MatchTypeID)
SELECT DISTINCT
	m.ID, x.BrandID, 8 as MatchTypeID
FROM midi.CTLoad_MIDINewCombo_v2 m
CROSS APPLY (
	SELECT top(1) MID, MCCID, cc.BrandID, br.BrandName, cc.PaymentGatewayStatusID 
	FROM Trans.ConsumerCombination cc
	INNER JOIN Warehouse.Relational.Brand br
		ON cc.BrandID = br.BrandID	
	WHERE cc.BrandID not in (944, 943)
		and m.MCCID = cc.MCCID
		AND m.MID = cc.MID
		AND CASE WHEN cc.BrandID = 1224 AND m.Narrative_Cleaned NOT LIKE '%sl%w%' THEN 1 END IS NULL
) x
LEFT JOIN #ConsumerCombination mmb
	ON m.MID = mmb.MID
	AND m.MCCID = mmb.MCCID
WHERE NOT EXISTS (SELECT 1 FROM midi.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID)
	AND x.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND (
		(mmb.BrandIDs Is Not Null And (m.Narrative_Cleaned Like '%' + Left(x.BrandName, 1) + '%' Or x.BrandName Like '%' + Left(m.Narrative_Cleaned, 2) + '%'))
	OR 
		(mmb.BrandIDs Is Not Null And (m.Narrative_Cleaned Like '%' + Left(x.BrandName, 2) + '%' Or x.BrandName Like '%' + Left(m.Narrative_Cleaned, 3) + '%'))
	)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - MID, MCC [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



----------------------------------------------------------------------------------------
--Prefix ONLY
----------------------------------------------------------------------------------------
INSERT INTO MIDI.CTLoad_MIDINewCombo_PossibleBrands (ComboID, SuggestedBrandID, MatchTypeID)
SELECT DISTINCT
		m.ID, bm.BrandID, 9 as MatchTypeID
FROM MIDI.CTLoad_MIDINewCombo_v2 m
INNER JOIN midi.BrandMatch bm 
	On m.Narrative_Cleaned Like BM.Narrative
WHERE NOT EXISTS (SELECT 1 FROM Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Prefix ONLY [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
		


----------------------------------------------------------------------------------------
-- UPDATE INFORMATION IN MATCH TABLE -- EXEC gas.CTLoad_MIDINewCombo_UpdateMatchInfo_V2
----------------------------------------------------------------------------------------
UPDATE mnc
	SET SuggestedBrandID = pbm.SuggestedBrandID
		, MatchType = pbm.MatchTypeID
		, BrandProbability = pbm.BrandProbability
FROM MIDI.CTLoad_MIDINewCombo_v2 mnc
INNER JOIN (
	Select ID
		, ComboID
		, SuggestedBrandID
		, MatchTypeID
		, BrandProbability
		, Min(MatchTypeID) Over (Partition by ComboID) as MinMatchTypeID
	FROM MIDI.CTLoad_MIDINewCombo_PossibleBrands pb
) pbm
	ON mnc.ID = pbm.ComboID
WHERE MatchTypeID = MinMatchTypeID 
	AND mnc.SuggestedBrandID IS NULL



UPDATE mnc
	SET MatchCount = pbmc.MatchCount
FROM MIDI.CTLoad_MIDINewCombo_v2 mnc
INNER JOIN (
	SELECT ComboID, COUNT(*) AS MatchCount
	FROM MIDI.CTLoad_MIDINewCombo_PossibleBrands
	WHERE SuggestedBrandID NOT IN (943,944)
	GROUP BY ComboID
	HAVING COUNT(1) > 1	
) pbmc
	ON mnc.ID = pbmc.ComboID
WHERE mnc.SuggestedBrandID NOT IN (943,944)





------------------------------------
----Mark the rest as unbranded
------------------------------------
UPDATE MIDI.CTLoad_MIDINewCombo_v2
SET SuggestedBrandID = 944, MatchType = 11
WHERE SuggestedBrandID IS NULL

--match paypal
UPDATE MIDI.CTLoad_MIDINewCombo_v2 
SET SuggestedBrandID = 943, MatchType = 10
WHERE (Narrative LIKE '%PAYPAL%') -- OR Narrative LIKE 'PP*%')
	AND (SuggestedBrandID = 944 Or MatchType = 9)

--match iZettle
UPDATE MIDI.CTLoad_MIDINewCombo_v2
SET SuggestedBrandID = 1293, MatchType = 14
WHERE Narrative Like '%IZ *%'
	AND (SuggestedBrandID = 944 Or MatchType = 9)


--CHANGE SUGGESTED BRAND IDs ACCORDING TO EXCEPTIONS
UPDATE mnc
SET SuggestedBrandID = mc.BrandIDChange
FROM MIDI.CTLoad_MIDINewCombo_v2 mnc
INNER JOIN MIDI.MIDIBrandChange_MCC mc
	ON mnc.SuggestedBrandID = mc.BrandIDInitial
	AND mnc.MCCID = mc.MCCID

UPDATE mnc
SET SuggestedBrandID = mc.BrandIDChange
FROM MIDI.CTLoad_MIDINewCombo_v2 mnc
INNER JOIN MIDI.MIDIBrandChange_Narrative mc
	ON mnc.SuggestedBrandID = mc.BrandIDInitial
	AND mnc.Narrative_Cleaned LIKE mc.Narrative




RETURN 0 
