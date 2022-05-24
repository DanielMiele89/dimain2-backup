/*
--=====================================================================================================
 Card Transaction Processing (loop) 
 First stage rating of [CTLoad_InitialStage_RF] 
 Moves rated rows from [CTLoad_InitialStage_RF] to ConsumerTransactionHolding

 Second stage rating of [CTLoad_InitialStage_RF]
 Moves rated rows from [CTLoad_InitialStage_RF] to ConsumerTransactionHolding

 Moves unrated rows to CTLoad_MIDIHolding for manual processing
 Clears [CTLoad_InitialStage_RF] for the next run

 Takes about 10 minutes to run

Notes:
There was a FK constraint on ConsumerCombination but it was expensive to process and IMHO unnecessary, since
this column is populated programmatically. If it causes problems, here's the script for restoring the constraint:
ALTER TABLE [MIDI].[ConsumerTransactionHolding]  WITH NOCHECK ADD  CONSTRAINT [FK_midi_ConsumerTransactionHolding_Combination] FOREIGN KEY([ConsumerCombinationID])
REFERENCES [Trans].[ConsumerCombination] ([ConsumerCombinationID])
GO

ALTER TABLE [MIDI].[ConsumerTransactionHolding] CHECK CONSTRAINT [FK_midi_ConsumerTransactionHolding_Combination]
GO

--=====================================================================================================
*/
CREATE PROCEDURE [MIDI].[__GenericTransProcessing_Archived]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/*
DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT

SELECT @RowsAffected = COUNT(*) FROM [MIDI].[CTLoad_InitialStage_RF] cis
IF @RowsAffected = 0 BEGIN
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - No rows to process'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	RETURN 0
END
ELSE
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Starting first part'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

-- Collect previously-unseen MCCs from the new data

	INSERT INTO [Warehouse].[Relational].[MCCList] (MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
	SELECT	DISTINCT 
			MCC
		,	''
		,	''
		,	''
		,	1
	FROM [MIDI].[CTLoad_InitialStage_RF] cis
	WHERE NOT EXISTS (	SELECT 1
						FROM [Warehouse].[Relational].[MCCList] mcc
						WHERE mcc.MCC = cis.MCC)
	AND 1 = 2

-- 0 / 00:00:02

-- Collect previously-unseen CINs from the new data

	INSERT INTO [Derived].[CINList] (CIN)
	SELECT	DISTINCT
			ca.PrimaryCustomerID
	FROM [MIDI].[CTLoad_InitialStage_RF] cis
	INNER JOIN [Inbound].[Cards] ca
		ON CONVERT(uniqueidentifier, cis.CardID) = ca.CardID
	WHERE NOT EXISTS (	SELECT 1
						FROM [Derived].[CINList] cl
						WHERE CONVERT(VARCHAR, ca.PrimaryCustomerID) = cl.CIN)

	SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Collect previously-unseen CINs [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	
-- (1056 rows affected) / 00:02:58

	UPDATE cis
	SET	cis.LocationID = 0
	FROM [MIDI].[CTLoad_InitialStage_RF] cis

	UPDATE cis
	SET	cis.MCCID = m.MCCID
	FROM [MIDI].[CTLoad_InitialStage_RF] cis
	INNER JOIN [Warehouse].[Relational].[MCCList] m
		ON cis.MCC = m.MCC

	UPDATE cis
	SET	cis.CIN = ca.PrimaryCustomerID
	,	cis.BankID = ca.BankID
	FROM [MIDI].[CTLoad_InitialStage_RF] cis
	INNER JOIN [Inbound].[Cards] ca
		ON cis.CardID = ca.CardID

	UPDATE cis
	SET	cis.CINID = cl.CINID
	FROM [MIDI].[CTLoad_InitialStage_RF] cis
	INNER JOIN [Derived].[CINList] cl
		ON cis.CIN = cl.CIN

	UPDATE cis
	SET	cis.InputModeID = cim.InputModeID
	FROM [MIDI].[CTLoad_InitialStage_RF] cis
	INNER JOIN [Warehouse].[Relational].[CardInputMode] cim
		ON cis.CardInputMode = cim.CardInputMode

	-- (7,426,003 rows affected) / 00:01:58
	SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Update various columns [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


----------------------------------------------------------------------------------------------------
-- loop step [Set Non-Paypal Combinations] EXEC gas.CTLoad_CombinationsNonPaypal_Set
----------------------------------------------------------------------------------------------------

	UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM [MIDI].[CTLoad_InitialStage_RF] i
	INNER JOIN [Relational].ConsumerCombination c 
		ON c.MID = i.MID
		AND c.LocationCountry = i.MerchantCountry
		AND c.MCCID = i.MCCID
		--AND c.OriginatorID = i.OriginatorID
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal
		AND (c.IsHighVariance = 0 AND c.Narrative = i.MerchantName)

SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Non-Paypal Combinations (low variance - 1) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
FROM [MIDI].[CTLoad_InitialStage_RF] i
INNER JOIN Trans.ConsumerCombination c 
	ON c.MID = i.MID
	AND c.LocationCountry = i.MerchantCountry
	AND c.MCCID = i.MCCID
	--AND c.OriginatorID = i.OriginatorID
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
	AND (c.IsHighVariance = 0 AND LEFT(c.Narrative,18) = LEFT(i.MerchantCountry,18))
WHERE i.ConsumerCombinationID IS NULL
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Non-Paypal Combinations (low variance - 2) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
FROM [MIDI].[CTLoad_InitialStage_RF] i
INNER JOIN Trans.ConsumerCombination c 
	ON i.MID = c.MID
	AND i.MerchantCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	--AND i.OriginatorID = c.OriginatorID
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
	AND (c.IsHighVariance = 1 AND i.MerchantCountry LIKE c.Narrative)
WHERE i.ConsumerCombinationID IS NULL
-- (212,684 rows affected) / 00:01:04 
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Non-Paypal Combinations (high variance) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


----------------------------------------------------------------------------------------------------
-- loop step [Set Paypal Combinations] EXEC gas.CTLoad_CombinationsPaypal_Set
----------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#PaypalMIDNew') IS NOT NULL DROP TABLE #PaypalMIDNew
CREATE TABLE #PaypalMIDNew (MID VARCHAR(50) PRIMARY KEY, TranCount INT NOT NULL)
INSERT INTO #PaypalMIDNew (MID, TranCount)
SELECT MID, TranCount = COUNT(*)
FROM [MIDI].[CTLoad_InitialStage_RF]
WHERE MerchantName LIKE 'PAYPAL%'
	AND ConsumerCombinationID IS NULL
GROUP BY MID
HAVING COUNT(*) >= 10
-- (298 rows affected) / 00:00:01
		
INSERT INTO Trans.ConsumerCombination (BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
SELECT 142652, 943, '%', 'PAYPAL%', LocationCountry, MCCID, OriginatorID, 1, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END, 1
FROM [MIDI].[CTLoad_InitialStage_RF] i
WHERE i.ConsumerCombinationID IS NULL
	AND i.MerchantCountry LIKE 'PAYPAL%'
	AND i.MCCID IS NOT NULL
	AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)
	AND NOT EXISTS (
		SELECT 1 
		FROM Trans.ConsumerCombination cc
		WHERE cc.PaymentGatewayStatusID = 1
		AND i.MerchantCountry = cc.LocationCountry
		AND i.MCCID = cc.MCCID
		AND i.OriginatorID = cc.OriginatorID
	)
-- (0 rows affected) / 00:00:01
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - New Paypal Combinations [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

-- Update ConsumerCombinationID except for #PaypalMIDNew		
UPDATE i SET ConsumerCombinationID = x.ConsumerCombinationID, 
	RequiresSecondaryID = 1
FROM [MIDI].[CTLoad_InitialStage_RF] i -- ix_Stuff
CROSS APPLY (
	SELECT TOP 1 ConsumerCombinationID
	FROM Trans.ConsumerCombination c -- 572,304,491
	WHERE c.PaymentGatewayStatusID = 1
	AND i.MerchantCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
--	AND i.OriginatorID = c.OriginatorID
) x
WHERE i.MerchantCountry LIKE 'PAYPAL%'
	AND i.ConsumerCombinationID IS NULL
	AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)
-- (95,440 rows affected) / 00:00:01
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Paypal Combinations'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


----------------------------------------------------------------------------------------------------
-- loop step [Load CTLoad_PaypalSecondaryID] EXEC gas.CTLoad_PaypalSecondary_Fetch REDUNDANT
-- loop step [Match SecondaryIDs] gas.CTLoad_PaypalSecondaryIDs_Set
----------------------------------------------------------------------------------------------------
-- insert new secondary combinations


--INSERT INTO Warehouse.Relational.PaymentGatewaySecondaryDetail (ConsumerCombinationID, MID, Narrative)
--SELECT ConsumerCombinationID, MID, Narrative
--FROM [MIDI].[CTLoad_InitialStage_RF] s
--WHERE s.RequiresSecondaryID = 1 
--	AND NOT EXISTS (
--		SELECT 1
--		FROM Warehouse.Relational.PaymentGatewaySecondaryDetail p 
--		WHERE s.ConsumerCombinationID = p.ConsumerCombinationID
--		AND s.MID = p.MID
--		AND s.Narrative = p.Narrative
--	)


-- (2,411 rows affected) / 00:01:06
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match secondary combinations (1)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

----update rows with existing secondary combinations and newly inserted IDs
--UPDATE s SET SecondaryCombinationID = p.PaymentGatewayID
--FROM [MIDI].[CTLoad_InitialStage_RF] s
--INNER JOIN Warehouse.Relational.PaymentGatewaySecondaryDetail p 
--	ON s.ConsumerCombinationID = p.ConsumerCombinationID
--	AND s.MID = p.MID
--	AND s.MerchantCounty = p.Narrative
--WHERE s.RequiresSecondaryID = 1
--	AND s.SecondaryCombinationID IS NULL
---- (95,440 rows affected) / 00:00:02
--SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match secondary combinations (2)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



/*


----------------------------------------------------------------------------------------------------
-- loop step [Set LocationIDs] EXEC gas.CTLoad_LocationIDs_Set
----------------------------------------------------------------------------------------------------
-- SET VALID LOCATIONS 
-- this statement is really buggered in the original because the Location table has tons of dupes.

SET STATISTICS XML ON
UPDATE i
	SET LocationID = x.LocationID
FROM [MIDI].[CTLoad_InitialStage_RF] i
CROSS APPLY (
	SELECT LocationID = MIN(l.LocationID)
	FROM [MIDI].Location l 
	WHERE i.ConsumerCombinationID = l.ConsumerCombinationID
		AND i.LocationAddress = l.LocationAddress
		AND l.IsNonLocational = 0
) x
SET STATISTICS XML OFF
-- (7,174,280 rows affected) / 00:01:07
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match locations (locational)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--SET NON-LOCATION ADDRESSES
UPDATE i
	SET LocationID = x.LocationID
FROM [MIDI].[CTLoad_InitialStage_RF] i
CROSS APPLY (
	SELECT LocationID = MIN(l.LocationID)
	FROM [MIDI].[Location] l 
	WHERE i.ConsumerCombinationID = l.ConsumerCombinationID
		AND l.IsNonLocational = 1
) x
WHERE i.LocationID IS NULL
-- (251,723 rows affected) / 00:00:05
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match locations (non-locational)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--INSERT NEW LOCATIONS
INSERT INTO [MIDI].[Location] (ConsumerCombinationID, LocationAddress, IsNonLocational)
SELECT DISTINCT ConsumerCombinationID, LocationAddress, 0
FROM [MIDI].[CTLoad_InitialStage_RF]
WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NULL
-- (111 rows affected) / 00:00:00
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Match locations new [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT 

--SET NEW LOCATIONS
UPDATE i
	SET LocationID = x.LocationID
FROM [MIDI].[CTLoad_InitialStage_RF] i
CROSS APPLY (
	SELECT LocationID = MIN(l.LocationID)
	FROM [MIDI].[Location] l 
	WHERE l.IsNonLocational = 0
		AND i.ConsumerCombinationID = l.ConsumerCombinationID
		AND i.LocationAddress = l.LocationAddress
) x
WHERE i.LocationID IS NULL
-- (251723 rows affected) / 00:00:02
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match locations set'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



*/


----------------------------------------------------------------------------------------------------
-- loop step [Distribute Transactions] EXEC gas.[CTLoad_InitialStage_RF]CINID_Fetch
----------------------------------------------------------------------------------------------------
-- InputModeID is no longer checked because cross database FK constraints aren't supported ###################
-- Load rated rows into the holding table for pushing into the permanent table
INSERT INTO [MIDI].ConsumerTransactionHolding (
	FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, LocationID, CardholderPresentData, 
	TranDate, CINID, Amount, IsRefund, IsOnline, InputModeID, /*PostStatusID,*/ PaymentTypeID	
)
SELECT 
	FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, LocationID = 0, CardholderPresentData, 
	TranDate, CINID, Amount, IsRefund, IsOnline, InputModeID, /*PostStatusID,*/ PaymentTypeID	
FROM [MIDI].[CTLoad_InitialStage_RF]
WHERE CINID IS NOT NULL
	AND ConsumerCombinationID IS not NULL 
	--AND LocationID IS not NULL
	AND TranDate > '19000101'
ORDER BY FileID, RowNum
-- (7,167,273 rows affected) / 00:02:18 
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture matched transactions to holding [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

;WITH RowToUpdate AS (SELECT TOP(1) * FROM [MIDI].GenericTrans_FilesProcessed ORDER BY FileID DESC)
UPDATE RowToUpdate SET 
	RowsProcessed = ISNULL(RowsProcessed,0) + ISNULL(@RowsAffected,0),
	ProcessedDate = GETDATE() 

----------------------------------------------------------------------------------------------------
-- loop step [Clear holding tables] EXEC gas.CTLoad_StagingTables_Clear
----------------------------------------------------------------------------------------------------
--TRUNCATE TABLE [MIDI].CTLoad_PaypalSecondaryID

-- Capture remaining ratable rows, throw the rest away
IF OBJECT_ID('tempdb..#CTLoad_InitialStage_RF') IS NOT NULL DROP TABLE #CTLoad_InitialStage_RF;
SELECT *
INTO #CTLoad_InitialStage_RF
FROM [MIDI].[CTLoad_InitialStage_RF]
WHERE CINID IS NOT NULL
	--AND (ConsumerCombinationID IS NULL OR LocationID IS NULL)
	AND (ConsumerCombinationID IS NULL)

TRUNCATE TABLE [MIDI].[CTLoad_InitialStage_RF]

INSERT INTO [MIDI].[CTLoad_InitialStage_RF] (
	FileID, RowNum, BankID, BankIDString, MID, Narrative, LocationAddress, LocationCountry, CardholderPresentData, TranDate
	, CINID, Amount, IsOnline, IsRefund, OriginatorID, MCC, MCCID, PostStatus, PostStatusID, LocationID, ConsumerCombinationID
	, SecondaryCombinationID, InputModeID, PaymentTypeID)
SELECT FileID, RowNum, BankID, BankIDString, MID, Narrative, LocationAddress, LocationCountry, CardholderPresentData, TranDate
	, CINID, Amount, IsOnline, IsRefund, OriginatorID, MCC, MCCID, PostStatus, PostStatusID, LocationID = 0, ConsumerCombinationID
	, SecondaryCombinationID, InputModeID, PaymentTypeID
FROM #CTLoad_InitialStage_RF
-- (37579 rows affected)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture unmatched transactions [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - End of first part'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

----------------------------------------------------------------------------------------------------
-- EXEC gas.CTLoad_MainTableLoad_Fetch
--DECLARE @DayName VARCHAR(50) = UPPER(DATENAME(DW, GETDATE()))
--SELECT CAST(CASE @DayName WHEN 'SATURDAY' THEN 1 WHEN 'SUNDAY' THEN 2 ELSE 0 END AS INT) AS MainTableLoadOrMIDI
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- EXEC gas.CTLoad_ConsumerTransactionHolding_DisableIndexes
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- EXEC gas.CTLoad_CombinationsMIDIHolding_Set
--DECLARE @PaypalCount INT
----------------------------------------------------------------------------------------------------




SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Start of second part'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--update non-high variance non-paypal combinations
UPDATE i
SET ConsumerCombinationID = c.ConsumerCombinationID
FROM [MIDI].[CTLoad_InitialStage_RF] i
INNER JOIN Trans.ConsumerCombination c ON
	i.MID = c.MID
	AND i.MerchantCountry = c.Narrative
	AND i.MerchantCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	--AND i.OriginatorID = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND c.IsHighVariance = 0
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - update non-paypal combinations (low variance - 1) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--update non-high variance non-paypal combinations
UPDATE i
SET ConsumerCombinationID = c.ConsumerCombinationID
FROM [MIDI].[CTLoad_InitialStage_RF] i
INNER JOIN Trans.ConsumerCombination c ON
	i.MID = c.MID
	AND LEFT(i.MerchantCountry,18) = LEFT(c.Narrative,18)
	AND i.MerchantCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	--AND i.OriginatorID = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND c.IsHighVariance = 0
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - update non-paypal combinations (low variance - 2) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--update high variance non-paypal combinations
UPDATE i
SET ConsumerCombinationID = c.ConsumerCombinationID
FROM [MIDI].[CTLoad_InitialStage_RF] i
INNER JOIN Trans.ConsumerCombination c ON
	i.MID = c.MID
	AND i.MerchantCountry LIKE c.Narrative
	AND i.MerchantCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	--AND i.OriginatorID = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND c.IsHighVariance = 1
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - update non-paypal combinations (high variance) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


------------------------------------------------------------------

--update paypal combinations
UPDATE cth
	SET ConsumerCombinationID = c.ConsumerCombinationID
	, RequiresSecondaryID = 1
FROM [MIDI].[CTLoad_InitialStage_RF] cth
INNER JOIN Trans.ConsumerCombination c
	ON cth.MerchantCountry = c.LocationCountry 
	AND cth.MCCID = c.MCCID 
	--AND cth.OriginatorID = c.OriginatorID
WHERE cth.ConsumerCombinationID IS NULL
	AND cth.MerchantName LIKE 'PAYPAL%'
	AND c.PaymentGatewayStatusID = 1
-- (13,913 rows affected) / 00:00:01
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - update paypal combinations [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

UPDATE cth
	SET SecondaryCombinationID = p.PaymentGatewayID
FROM [MIDI].[CTLoad_InitialStage_RF] cth
INNER JOIN [MIDI].PaymentGatewaySecondaryDetail p 
	ON cth.ConsumerCombinationID = p.ConsumerCombinationID
	AND cth.MID = p.MID
	AND cth.MerchantName = p.Narrative
WHERE cth.SecondaryCombinationID IS NULL
	AND cth.RequiresSecondaryID = 1
-- (2936 rows affected) / 00:00:00


INSERT INTO [MIDI].PaymentGatewaySecondaryDetail (ConsumerCombinationID, MID, Narrative)
SELECT ConsumerCombinationID, MID, MerchantName
FROM [MIDI].[CTLoad_InitialStage_RF]
WHERE RequiresSecondaryID = 1
	AND SecondaryCombinationID IS NULL
-- (10977 rows affected) / 00:00:00

UPDATE cth
	SET SecondaryCombinationID = p.PaymentGatewayID
FROM [MIDI].[CTLoad_InitialStage_RF] cth
INNER JOIN [MIDI].PaymentGatewaySecondaryDetail p 
	ON cth.ConsumerCombinationID = p.ConsumerCombinationID
	AND cth.MID = p.MID
	AND cth.MerchantName = p.Narrative
WHERE cth.SecondaryCombinationID IS NULL
	AND cth.RequiresSecondaryID = 1
-- (10977 rows affected) / 00:00:02


/*
-- EXEC gas.CTLoad_LocationIDsMIDIHolding_Set
INSERT INTO [MIDI].[Location] (ConsumerCombinationID, LocationAddress, IsNonLocational)
SELECT DISTINCT ConsumerCombinationID, LocationAddress, 0
FROM [MIDI].[CTLoad_InitialStage_RF]
WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NULL
-- (1014 rows affected) / 00:00:01

-- set new locations
UPDATE i
	SET LocationID = L.LocationID
FROM [MIDI].[CTLoad_InitialStage_RF] i
INNER JOIN [MIDI].[Location] l 
	ON i.ConsumerCombinationID = l.ConsumerCombinationID
	AND i.LocationAddress = l.LocationAddress
WHERE l.IsNonLocational = 0
	AND i.LocationID IS NULL
-- (5098 rows affected) / 00:00:05
*/



-- EXEC gas.CombinationsMIDIHolding_Fetch -- >> Relational.ConsumerTransactionHolding
INSERT INTO [MIDI].ConsumerTransactionHolding (
	FileID, RowNum, BankID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, IsRefund, 
	/*PostStatusID, */ LocationID, ConsumerCombinationID, SecondaryCombinationID, InputModeID, PaymentTypeID)
SELECT FileID, RowNum, BankID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, IsRefund, 
	/*PostStatusID, */LocationID = 0, ConsumerCombinationID, SecondaryCombinationID, InputModeID, PaymentTypeID
FROM [MIDI].[CTLoad_InitialStage_RF]
WHERE ConsumerCombinationID IS NOT NULL
	--AND LocationID IS NOT NULL
-- (5098 rows affected) / 00:00:03
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture matched transactions to holding [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


-- EXEC gas.CTLoad_MIDIHoldingCombinations_Clear
DELETE FROM [MIDI].[CTLoad_InitialStage_RF]
WHERE ConsumerCombinationID IS NOT NULL
	--AND LocationID IS NOT NULL
-- (5098 rows affected) / 00:00:00


-- Load unrated rows into a separate table for further (manual) processing [MIDI].[MIDI_Module]
INSERT INTO [MIDI].[CTLoad_MIDIHolding] (
	FileID, RowNum, BankID, MID, Narrative, LocationAddress, LocationCountry, CardholderPresentData, TranDate
	, CINID, Amount, IsOnline, IsRefund, /*OriginatorID, */MCCID, /*PostStatusID, */ LocationID, ConsumerCombinationID
	, SecondaryCombinationID, InputModeID, PaymentTypeID)
SELECT FileID, RowNum, BankID, MID, MerchantName, LocationAddress, MerchantCountry, CardholderPresentData, TranDate
	, CINID, Amount, IsOnline, IsRefund, /*OriginatorID, */MCCID, /*PostStatusID, */LocationID = 0, ConsumerCombinationID
	, SecondaryCombinationID, InputModeID, PaymentTypeID
FROM [MIDI].[CTLoad_InitialStage_RF]
WHERE CINID IS NOT NULL
	--AND (ConsumerCombinationID IS NULL OR LocationID IS NULL)
	AND (ConsumerCombinationID IS NULL)
-- (249,905 rows affected) / 00:00:03
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture remaining matchable transactions for manual processing [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


UPDATE p SET 
	RowsProcessed = ISNULL(RowsProcessed,0) + ISNULL(@RowsAffected,0),
	ProcessedDate = GETDATE()  
FROM [MIDI].GenericTrans_FilesProcessed p
INNER JOIN (SELECT FileID FROM [MIDI].[CTLoad_InitialStage_RF] GROUP BY FileID) s ON s.FileID = p.FileID


-- loop step [QA Logging] EXEC gas.CTLoad_QAStats_Set 
INSERT INTO [MIDI].CardTransaction_QA (FileID, FileCount, MatchedCount, UnmatchedCount, NoCINCount, PositiveCount)
SELECT FileID
	, COUNT(1) AS FileCount
	, SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 0 ELSE 1 END) AS MatchedCount
	, SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 1 ELSE 0 END) AS UnmatchedCount
	, SUM(CASE WHEN CINID IS NULL THEN 0 ELSE 1 END) AS NoCINCount
	, SUM(CASE WHEN IsRefund = 0 THEN 1 ELSE 0 END) AS PositiveCount
FROM [MIDI].[CTLoad_InitialStage_RF]
GROUP BY FileID
-- (1 row affected) / 00:00:01


TRUNCATE TABLE [MIDI].[CTLoad_InitialStage_RF]

SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - End of second part'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

*/

RETURN 0 


