/*
--=====================================================================================================
 Card Transaction Processing (loop) 
 First stage rating of CTLoad_InitialStage 
 Moves rated rows from CTLoad_InitialStage to ConsumerTransactionHolding

 Second stage rating of CTLoad_InitialStage
 Moves rated rows from CTLoad_InitialStage to ConsumerTransactionHolding

 Moves unrated rows to CTLoad_MIDIHolding for manual processing
 Clears CTLoad_InitialStage for the next run

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
CREATE PROCEDURE [MIDI].[__GenericTransProcessing_2_Archived]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT

SELECT @RowsAffected = COUNT(*) FROM MIDI.CTLoad_InitialStage cis
IF @RowsAffected = 0 BEGIN
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - No rows to process'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	RETURN 0
END
ELSE
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Starting first part'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

-- LocationID

----------------------------------------------------------------------------------------------------
-- loop step [Set Column Values] EXEC gas.CTLoad_SetInitialColumnValues
----------------------------------------------------------------------------------------------------
-- Collect previously-unseen MCCs from the new data
INSERT INTO Warehouse.Relational.MCCList ([Warehouse].[Relational].[MCCList].[MCC], [Warehouse].[Relational].[MCCList].[MCCGroup], [Warehouse].[Relational].[MCCList].[MCCCategory], [Warehouse].[Relational].[MCCList].[MCCDesc], [Warehouse].[Relational].[MCCList].[SectorID])
SELECT DISTINCT [cis].[MCC], '', '', '', 1
FROM MIDI.CTLoad_InitialStage cis
WHERE NOT EXISTS (SELECT 1 FROM Warehouse.Relational.MCCList mcc WHERE [MIDI].[CTLoad_InitialStage].[mcc].MCC = cis.MCC)
-- 0 / 00:00:02

-- Collect previously-unseen CINs from the new data
INSERT INTO Derived.CINList ([Derived].[CINList].[CIN])
SELECT DISTINCT ic.SourceUID
FROM MIDI.CTLoad_InitialStage cis
INNER JOIN SLC_Report.dbo.IssuerPaymentCard ipc 
	ON ipc.PaymentCardID = cis.PaymentCardID
INNER JOIN SLC_Report.dbo.IssuerCustomer ic 
	ON ipc.IssuerCustomerID = ic.ID
EXCEPT
SELECT [Derived].[CINList].[CIN]
FROM Derived.CINList
-- (1056 rows affected) / 00:02:58
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Collect previously-unseen CINs [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

UPDATE cis SET 
	[cis].[MCCID] = m.MCCID,
	[MIDI].[CTLoad_InitialStage].[PostStatusID] = p.PostStatusID,
	[cis].[CIN] = ic.SourceUID,
	[cis].[BankID] = b.BankID,
	[cis].[InputModeID] = c.InputModeID,
	[cis].[CINID] = cl.CINID,
	[cis].[LocationID] = 0
FROM MIDI.CTLoad_InitialStage cis
INNER JOIN SLC_Report.dbo.IssuerPaymentCard ipc
	ON ipc.PaymentCardID = cis.PaymentCardID
INNER JOIN SLC_Report.dbo.IssuerCustomer ic 
	ON ipc.IssuerCustomerID = ic.ID
INNER JOIN Derived.CINList cl 
	ON cl.CIN = ic.SourceUID
LEFT JOIN Warehouse.Relational.MCCList m 
	ON cis.MCC = m.MCC  
LEFT JOIN Warehouse.Relational.PostStatus p 
	ON cis.PostStatus = p.PostStatusDesc
LEFT JOIN Warehouse.Relational.CardTransactionBank b 
	ON cis.BankIDString = b.BankIdentifier
LEFT JOIN Warehouse.Relational.CardInputMode c 
	ON cis.CardInputMode = c.CardInputMode

-- (7,426,003 rows affected) / 00:01:58
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Update various columns [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


----------------------------------------------------------------------------------------------------
-- loop step [Set Non-Paypal Combinations] EXEC gas.CTLoad_CombinationsNonPaypal_Set
----------------------------------------------------------------------------------------------------
UPDATE i
	SET [i].[ConsumerCombinationID] = c.ConsumerCombinationID
FROM MIDI.CTLoad_InitialStage i
INNER JOIN Trans.ConsumerCombination c 
	ON c.MID = i.MID
	AND c.LocationCountry = i.LocationCountry
	AND c.MCCID = i.MCCID
	AND c.OriginatorID = i.OriginatorID
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
	AND (c.IsHighVariance = 0 AND c.Narrative = i.Narrative)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Non-Paypal Combinations (low variance - 1) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

UPDATE i
	SET [i].[ConsumerCombinationID] = c.ConsumerCombinationID
FROM MIDI.CTLoad_InitialStage i
INNER JOIN Trans.ConsumerCombination c 
	ON c.MID = i.MID
	AND c.LocationCountry = i.LocationCountry
	AND c.MCCID = i.MCCID
	AND c.OriginatorID = i.OriginatorID
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
	AND (c.IsHighVariance = 0 AND LEFT(c.Narrative,18) = LEFT(i.Narrative,18))
WHERE i.ConsumerCombinationID IS NULL
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Non-Paypal Combinations (low variance - 2) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

UPDATE i
	SET [i].[ConsumerCombinationID] = c.ConsumerCombinationID
FROM MIDI.CTLoad_InitialStage i
INNER JOIN Trans.ConsumerCombination c 
	ON i.MID = c.MID
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorID = c.OriginatorID
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
	AND (c.IsHighVariance = 1 AND i.Narrative LIKE c.Narrative)
WHERE i.ConsumerCombinationID IS NULL
-- (212,684 rows affected) / 00:01:04 
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Non-Paypal Combinations (high variance) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


----------------------------------------------------------------------------------------------------
-- loop step [Set Paypal Combinations] EXEC gas.CTLoad_CombinationsPaypal_Set
----------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#PaypalMIDNew') IS NOT NULL DROP TABLE #PaypalMIDNew
CREATE TABLE #PaypalMIDNew (MID VARCHAR(50) PRIMARY KEY, TranCount INT NOT NULL)
INSERT INTO #PaypalMIDNew (#PaypalMIDNew.[MID], #PaypalMIDNew.[TranCount])
SELECT [MIDI].[CTLoad_InitialStage].[MID], TranCount = COUNT(*)
FROM MIDI.CTLoad_InitialStage
WHERE [MIDI].[CTLoad_InitialStage].[Narrative] LIKE 'PAYPAL%'
	AND [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID] IS NULL
GROUP BY [MIDI].[CTLoad_InitialStage].[MID]
HAVING COUNT(*) >= 10
-- (298 rows affected) / 00:00:01
		
INSERT INTO Trans.ConsumerCombination ([Trans].[ConsumerCombination].[BrandMIDID], [Trans].[ConsumerCombination].[BrandID], [Trans].[ConsumerCombination].[MID], [Trans].[ConsumerCombination].[Narrative], [Trans].[ConsumerCombination].[LocationCountry], [Trans].[ConsumerCombination].[MCCID], [Trans].[ConsumerCombination].[OriginatorID], [Trans].[ConsumerCombination].[IsHighVariance], [Trans].[ConsumerCombination].[IsUKSpend], [Trans].[ConsumerCombination].[PaymentGatewayStatusID])
SELECT 142652, 943, '%', 'PAYPAL%', [MIDI].[CTLoad_InitialStage].[LocationCountry], [i].[MCCID], [MIDI].[CTLoad_InitialStage].[OriginatorID], 1, CASE WHEN [MIDI].[CTLoad_InitialStage].[LocationCountry] = 'GB' THEN 1 ELSE 0 END, 1
FROM MIDI.CTLoad_InitialStage i
WHERE i.ConsumerCombinationID IS NULL
	AND i.Narrative LIKE 'PAYPAL%'
	AND i.MCCID IS NOT NULL
	AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE #PaypalMIDNew.[i].MID = pn.MID)
	AND NOT EXISTS (
		SELECT 1 
		FROM Trans.ConsumerCombination cc
		WHERE cc.PaymentGatewayStatusID = 1
		AND i.LocationCountry = cc.LocationCountry
		AND i.MCCID = cc.MCCID
		AND i.OriginatorID = cc.OriginatorID
	)
-- (0 rows affected) / 00:00:01
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - New Paypal Combinations [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

-- Update ConsumerCombinationID except for #PaypalMIDNew		
UPDATE i SET [i].[ConsumerCombinationID] = x.ConsumerCombinationID, 
	[i].[RequiresSecondaryID] = 1
FROM MIDI.CTLoad_InitialStage i -- ix_Stuff
CROSS APPLY (
	SELECT TOP 1 [c].[ConsumerCombinationID]
	FROM Trans.ConsumerCombination c -- 572,304,491
	WHERE c.PaymentGatewayStatusID = 1
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorID = c.OriginatorID
) x
WHERE i.Narrative LIKE 'PAYPAL%'
	AND i.ConsumerCombinationID IS NULL
	AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE #PaypalMIDNew.[i].MID = pn.MID)
-- (95,440 rows affected) / 00:00:01
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Paypal Combinations'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


----------------------------------------------------------------------------------------------------
-- loop step [Load CTLoad_PaypalSecondaryID] EXEC gas.CTLoad_PaypalSecondary_Fetch REDUNDANT
-- loop step [Match SecondaryIDs] gas.CTLoad_PaypalSecondaryIDs_Set
----------------------------------------------------------------------------------------------------
-- insert new secondary combinations
INSERT INTO Warehouse.Relational.PaymentGatewaySecondaryDetail ([Warehouse].[Relational].[PaymentGatewaySecondaryDetail].[ConsumerCombinationID], [Warehouse].[Relational].[PaymentGatewaySecondaryDetail].[MID], [Warehouse].[Relational].[PaymentGatewaySecondaryDetail].[Narrative])
SELECT [s].[ConsumerCombinationID], [s].[MID], [MIDI].[CTLoad_InitialStage].[Narrative]
FROM MIDI.CTLoad_InitialStage s
WHERE s.RequiresSecondaryID = 1 
	AND NOT EXISTS (
		SELECT 1
		FROM Warehouse.Relational.PaymentGatewaySecondaryDetail p 
		WHERE s.ConsumerCombinationID = p.ConsumerCombinationID
		AND s.MID = p.MID
		AND s.Narrative = p.Narrative
	)
-- (2,411 rows affected) / 00:01:06
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match secondary combinations (1)'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--update rows with existing secondary combinations and newly inserted IDs
UPDATE s SET [s].[SecondaryCombinationID] = p.PaymentGatewayID
FROM MIDI.CTLoad_InitialStage s
INNER JOIN Warehouse.Relational.PaymentGatewaySecondaryDetail p 
	ON s.ConsumerCombinationID = p.ConsumerCombinationID
	AND s.MID = p.MID
	AND s.Narrative = p.Narrative
WHERE s.RequiresSecondaryID = 1
	AND s.SecondaryCombinationID IS NULL
-- (95,440 rows affected) / 00:00:02
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match secondary combinations (2)'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



/*


----------------------------------------------------------------------------------------------------
-- loop step [Set LocationIDs] EXEC gas.CTLoad_LocationIDs_Set
----------------------------------------------------------------------------------------------------
-- SET VALID LOCATIONS 
-- this statement is really buggered in the original because the Location table has tons of dupes.

SET STATISTICS XML ON
UPDATE i
	SET LocationID = x.LocationID
FROM MIDI.CTLoad_InitialStage i
CROSS APPLY (
	SELECT LocationID = MIN(l.LocationID)
	FROM MIDI.Location l 
	WHERE i.ConsumerCombinationID = l.ConsumerCombinationID
		AND i.LocationAddress = l.LocationAddress
		AND l.IsNonLocational = 0
) x
SET STATISTICS XML OFF
-- (7,174,280 rows affected) / 00:01:07
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match locations (locational)'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--SET NON-LOCATION ADDRESSES
UPDATE i
	SET LocationID = x.LocationID
FROM MIDI.CTLoad_InitialStage i
CROSS APPLY (
	SELECT LocationID = MIN(l.LocationID)
	FROM MIDI.[Location] l 
	WHERE i.ConsumerCombinationID = l.ConsumerCombinationID
		AND l.IsNonLocational = 1
) x
WHERE i.LocationID IS NULL
-- (251,723 rows affected) / 00:00:05
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match locations (non-locational)'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--INSERT NEW LOCATIONS
INSERT INTO MIDI.[Location] (ConsumerCombinationID, LocationAddress, IsNonLocational)
SELECT DISTINCT ConsumerCombinationID, LocationAddress, 0
FROM MIDI.CTLoad_InitialStage
WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NULL
-- (111 rows affected) / 00:00:00
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Match locations new [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT 

--SET NEW LOCATIONS
UPDATE i
	SET LocationID = x.LocationID
FROM MIDI.CTLoad_InitialStage i
CROSS APPLY (
	SELECT LocationID = MIN(l.LocationID)
	FROM MIDI.[Location] l 
	WHERE l.IsNonLocational = 0
		AND i.ConsumerCombinationID = l.ConsumerCombinationID
		AND i.LocationAddress = l.LocationAddress
) x
WHERE i.LocationID IS NULL
-- (251723 rows affected) / 00:00:02
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match locations set'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



*/


----------------------------------------------------------------------------------------------------
-- loop step [Distribute Transactions] EXEC gas.CTLoad_InitialStageCINID_Fetch
----------------------------------------------------------------------------------------------------
-- InputModeID is no longer checked because cross database FK constraints aren't supported ###################
-- Load rated rows into the holding table for pushing into the permanent table
INSERT INTO MIDI.ConsumerTransactionHolding (
	[MIDI].[ConsumerTransactionHolding].[FileID], [MIDI].[ConsumerTransactionHolding].[RowNum], [MIDI].[ConsumerTransactionHolding].[ConsumerCombinationID], [MIDI].[ConsumerTransactionHolding].[SecondaryCombinationID], [MIDI].[ConsumerTransactionHolding].[BankID], [MIDI].[ConsumerTransactionHolding].[LocationID], [MIDI].[ConsumerTransactionHolding].[CardholderPresentData], 
	[MIDI].[ConsumerTransactionHolding].[TranDate], [MIDI].[ConsumerTransactionHolding].[CINID], [MIDI].[ConsumerTransactionHolding].[Amount], [MIDI].[ConsumerTransactionHolding].[IsRefund], [MIDI].[ConsumerTransactionHolding].[IsOnline], [MIDI].[ConsumerTransactionHolding].[InputModeID], [MIDI].[ConsumerTransactionHolding].[PostStatusID], [MIDI].[ConsumerTransactionHolding].[PaymentTypeID]	
)
SELECT 
	[MIDI].[CTLoad_InitialStage].[FileID], [MIDI].[CTLoad_InitialStage].[RowNum], [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID], [MIDI].[CTLoad_InitialStage].[SecondaryCombinationID], [MIDI].[CTLoad_InitialStage].[BankID], LocationID = 0, [MIDI].[CTLoad_InitialStage].[CardholderPresentData], 
	[MIDI].[CTLoad_InitialStage].[TranDate], [MIDI].[CTLoad_InitialStage].[CINID], [MIDI].[CTLoad_InitialStage].[Amount], [MIDI].[CTLoad_InitialStage].[IsRefund], [MIDI].[CTLoad_InitialStage].[IsOnline], [MIDI].[CTLoad_InitialStage].[InputModeID], [MIDI].[CTLoad_InitialStage].[PostStatusID], [MIDI].[CTLoad_InitialStage].[PaymentTypeID]	
FROM MIDI.CTLoad_InitialStage
WHERE [MIDI].[CTLoad_InitialStage].[CINID] IS NOT NULL
	AND [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID] IS not NULL 
	--AND LocationID IS not NULL
	AND [MIDI].[CTLoad_InitialStage].[TranDate] > '19000101'
ORDER BY [MIDI].[CTLoad_InitialStage].[FileID], [MIDI].[CTLoad_InitialStage].[RowNum]
-- (7,167,273 rows affected) / 00:02:18 
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture matched transactions to holding [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

;WITH RowToUpdate AS (SELECT TOP(1) * FROM MIDI.GenericTrans_FilesProcessed ORDER BY [MIDI].[GenericTrans_FilesProcessed].[FileID] DESC)
UPDATE RowToUpdate SET 
	[MIDI].[GenericTrans_FilesProcessed].[RowsProcessed] = ISNULL([MIDI].[GenericTrans_FilesProcessed].[RowsProcessed],0) + ISNULL(@RowsAffected,0),
	[MIDI].[GenericTrans_FilesProcessed].[ProcessedDate] = GETDATE() 

----------------------------------------------------------------------------------------------------
-- loop step [Clear holding tables] EXEC gas.CTLoad_StagingTables_Clear
----------------------------------------------------------------------------------------------------
--TRUNCATE TABLE MIDI.CTLoad_PaypalSecondaryID

-- Capture remaining ratable rows, throw the rest away
IF OBJECT_ID('tempdb..#CTLoad_InitialStage') IS NOT NULL DROP TABLE #CTLoad_InitialStage;
SELECT *
INTO #CTLoad_InitialStage
FROM MIDI.CTLoad_InitialStage
WHERE [MIDI].[CTLoad_InitialStage].[CINID] IS NOT NULL
	--AND (ConsumerCombinationID IS NULL OR LocationID IS NULL)
	AND ([MIDI].[CTLoad_InitialStage].[ConsumerCombinationID] IS NULL)

TRUNCATE TABLE MIDI.CTLoad_InitialStage

INSERT INTO MIDI.CTLoad_InitialStage (
	[MIDI].[CTLoad_InitialStage].[FileID], [MIDI].[CTLoad_InitialStage].[RowNum], [MIDI].[CTLoad_InitialStage].[BankID], [MIDI].[CTLoad_InitialStage].[BankIDString], [MIDI].[CTLoad_InitialStage].[MID], [MIDI].[CTLoad_InitialStage].[Narrative], [MIDI].[CTLoad_InitialStage].[LocationAddress], [MIDI].[CTLoad_InitialStage].[LocationCountry], [MIDI].[CTLoad_InitialStage].[CardholderPresentData], [MIDI].[CTLoad_InitialStage].[TranDate]
	, [MIDI].[CTLoad_InitialStage].[CINID], [MIDI].[CTLoad_InitialStage].[Amount], [MIDI].[CTLoad_InitialStage].[IsOnline], [MIDI].[CTLoad_InitialStage].[IsRefund], [MIDI].[CTLoad_InitialStage].[OriginatorID], [MIDI].[CTLoad_InitialStage].[MCC], [MIDI].[CTLoad_InitialStage].[MCCID], [MIDI].[CTLoad_InitialStage].[PostStatus], [MIDI].[CTLoad_InitialStage].[PostStatusID], [MIDI].[CTLoad_InitialStage].[LocationID], [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID]
	, [MIDI].[CTLoad_InitialStage].[SecondaryCombinationID], [MIDI].[CTLoad_InitialStage].[InputModeID], [MIDI].[CTLoad_InitialStage].[PaymentTypeID])
SELECT #CTLoad_InitialStage.[FileID], #CTLoad_InitialStage.[RowNum], #CTLoad_InitialStage.[BankID], #CTLoad_InitialStage.[BankIDString], #CTLoad_InitialStage.[MID], #CTLoad_InitialStage.[Narrative], #CTLoad_InitialStage.[LocationAddress], #CTLoad_InitialStage.[LocationCountry], #CTLoad_InitialStage.[CardholderPresentData], #CTLoad_InitialStage.[TranDate]
	, #CTLoad_InitialStage.[CINID], #CTLoad_InitialStage.[Amount], #CTLoad_InitialStage.[IsOnline], #CTLoad_InitialStage.[IsRefund], #CTLoad_InitialStage.[OriginatorID], #CTLoad_InitialStage.[MCC], #CTLoad_InitialStage.[MCCID], #CTLoad_InitialStage.[PostStatus], #CTLoad_InitialStage.[PostStatusID], LocationID = 0, #CTLoad_InitialStage.[ConsumerCombinationID]
	, #CTLoad_InitialStage.[SecondaryCombinationID], #CTLoad_InitialStage.[InputModeID], #CTLoad_InitialStage.[PaymentTypeID]
FROM #CTLoad_InitialStage
-- (37579 rows affected)
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture unmatched transactions [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - End of first part'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

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




SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Start of second part'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--update non-high variance non-paypal combinations
UPDATE i
SET [i].[ConsumerCombinationID] = c.ConsumerCombinationID
FROM MIDI.CTLoad_InitialStage i
INNER JOIN Trans.ConsumerCombination c ON
	i.MID = c.MID
	AND i.Narrative = c.Narrative
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorID = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND c.IsHighVariance = 0
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - update non-paypal combinations (low variance - 1) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--update non-high variance non-paypal combinations
UPDATE i
SET [i].[ConsumerCombinationID] = c.ConsumerCombinationID
FROM MIDI.CTLoad_InitialStage i
INNER JOIN Trans.ConsumerCombination c ON
	i.MID = c.MID
	AND LEFT(i.Narrative,18) = LEFT(c.Narrative,18)
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorID = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND c.IsHighVariance = 0
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - update non-paypal combinations (low variance - 2) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

--update high variance non-paypal combinations
UPDATE i
SET [i].[ConsumerCombinationID] = c.ConsumerCombinationID
FROM MIDI.CTLoad_InitialStage i
INNER JOIN Trans.ConsumerCombination c ON
	i.MID = c.MID
	AND i.Narrative LIKE c.Narrative
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorID = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND c.IsHighVariance = 1
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - update non-paypal combinations (high variance) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


------------------------------------------------------------------

--update paypal combinations
UPDATE cth
	SET [cth].[ConsumerCombinationID] = c.ConsumerCombinationID
	, [cth].[RequiresSecondaryID] = 1
FROM MIDI.CTLoad_InitialStage cth
INNER JOIN Trans.ConsumerCombination c
	ON cth.LocationCountry = c.LocationCountry 
	AND cth.MCCID = c.MCCID 
	AND cth.OriginatorID = c.OriginatorID
WHERE cth.ConsumerCombinationID IS NULL
	AND cth.Narrative LIKE 'PAYPAL%'
	AND c.PaymentGatewayStatusID = 1
-- (13,913 rows affected) / 00:00:01
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - update paypal combinations [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

UPDATE cth
	SET [cth].[SecondaryCombinationID] = p.PaymentGatewayID
FROM MIDI.CTLoad_InitialStage cth
INNER JOIN MIDI.PaymentGatewaySecondaryDetail p 
	ON cth.ConsumerCombinationID = p.ConsumerCombinationID
	AND cth.MID = p.MID
	AND cth.Narrative = p.Narrative
WHERE cth.SecondaryCombinationID IS NULL
	AND cth.RequiresSecondaryID = 1
-- (2936 rows affected) / 00:00:00


INSERT INTO MIDI.PaymentGatewaySecondaryDetail ([MIDI].[PaymentGatewaySecondaryDetail].[ConsumerCombinationID], [MIDI].[PaymentGatewaySecondaryDetail].[MID], [MIDI].[PaymentGatewaySecondaryDetail].[Narrative])
SELECT [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID], [MIDI].[CTLoad_InitialStage].[MID], [MIDI].[CTLoad_InitialStage].[Narrative]
FROM MIDI.CTLoad_InitialStage
WHERE [MIDI].[CTLoad_InitialStage].[RequiresSecondaryID] = 1
	AND [MIDI].[CTLoad_InitialStage].[SecondaryCombinationID] IS NULL
-- (10977 rows affected) / 00:00:00

UPDATE cth
	SET [cth].[SecondaryCombinationID] = p.PaymentGatewayID
FROM MIDI.CTLoad_InitialStage cth
INNER JOIN MIDI.PaymentGatewaySecondaryDetail p 
	ON cth.ConsumerCombinationID = p.ConsumerCombinationID
	AND cth.MID = p.MID
	AND cth.Narrative = p.Narrative
WHERE cth.SecondaryCombinationID IS NULL
	AND cth.RequiresSecondaryID = 1
-- (10977 rows affected) / 00:00:02


/*
-- EXEC gas.CTLoad_LocationIDsMIDIHolding_Set
INSERT INTO MIDI.[Location] (ConsumerCombinationID, LocationAddress, IsNonLocational)
SELECT DISTINCT ConsumerCombinationID, LocationAddress, 0
FROM MIDI.CTLoad_InitialStage
WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NULL
-- (1014 rows affected) / 00:00:01

-- set new locations
UPDATE i
	SET LocationID = L.LocationID
FROM MIDI.CTLoad_InitialStage i
INNER JOIN MIDI.[Location] l 
	ON i.ConsumerCombinationID = l.ConsumerCombinationID
	AND i.LocationAddress = l.LocationAddress
WHERE l.IsNonLocational = 0
	AND i.LocationID IS NULL
-- (5098 rows affected) / 00:00:05
*/



-- EXEC gas.CombinationsMIDIHolding_Fetch -- >> Relational.ConsumerTransactionHolding
INSERT INTO MIDI.ConsumerTransactionHolding (
	[MIDI].[ConsumerTransactionHolding].[FileID], [MIDI].[ConsumerTransactionHolding].[RowNum], [MIDI].[ConsumerTransactionHolding].[BankID], [MIDI].[ConsumerTransactionHolding].[CardholderPresentData], [MIDI].[ConsumerTransactionHolding].[TranDate], [MIDI].[ConsumerTransactionHolding].[CINID], [MIDI].[ConsumerTransactionHolding].[Amount], [MIDI].[ConsumerTransactionHolding].[IsOnline], [MIDI].[ConsumerTransactionHolding].[IsRefund], 
	[MIDI].[ConsumerTransactionHolding].[PostStatusID], [MIDI].[ConsumerTransactionHolding].[LocationID], [MIDI].[ConsumerTransactionHolding].[ConsumerCombinationID], [MIDI].[ConsumerTransactionHolding].[SecondaryCombinationID], [MIDI].[ConsumerTransactionHolding].[InputModeID], [MIDI].[ConsumerTransactionHolding].[PaymentTypeID])
SELECT [MIDI].[CTLoad_InitialStage].[FileID], [MIDI].[CTLoad_InitialStage].[RowNum], [MIDI].[CTLoad_InitialStage].[BankID], [MIDI].[CTLoad_InitialStage].[CardholderPresentData], [MIDI].[CTLoad_InitialStage].[TranDate], [MIDI].[CTLoad_InitialStage].[CINID], [MIDI].[CTLoad_InitialStage].[Amount], [MIDI].[CTLoad_InitialStage].[IsOnline], [MIDI].[CTLoad_InitialStage].[IsRefund], 
	[MIDI].[CTLoad_InitialStage].[PostStatusID], LocationID = 0, [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID], [MIDI].[CTLoad_InitialStage].[SecondaryCombinationID], [MIDI].[CTLoad_InitialStage].[InputModeID], [MIDI].[CTLoad_InitialStage].[PaymentTypeID]
FROM MIDI.CTLoad_InitialStage
WHERE [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID] IS NOT NULL
	--AND LocationID IS NOT NULL
-- (5098 rows affected) / 00:00:03
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture matched transactions to holding [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


-- EXEC gas.CTLoad_MIDIHoldingCombinations_Clear
DELETE FROM MIDI.CTLoad_InitialStage
WHERE [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID] IS NOT NULL
	--AND LocationID IS NOT NULL
-- (5098 rows affected) / 00:00:00


-- Load unrated rows into a separate table for further (manual) processing [MIDI].[MIDI_Module]
INSERT INTO [MIDI].[CTLoad_MIDIHolding] (
	[MIDI].[CTLoad_MIDIHolding].[FileID], [MIDI].[CTLoad_MIDIHolding].[RowNum], [MIDI].[CTLoad_MIDIHolding].[BankID], [MIDI].[CTLoad_MIDIHolding].[MID], [MIDI].[CTLoad_MIDIHolding].[Narrative], [MIDI].[CTLoad_MIDIHolding].[LocationAddress], [MIDI].[CTLoad_MIDIHolding].[LocationCountry], [MIDI].[CTLoad_MIDIHolding].[CardholderPresentData], [MIDI].[CTLoad_MIDIHolding].[TranDate]
	, [MIDI].[CTLoad_MIDIHolding].[CINID], [MIDI].[CTLoad_MIDIHolding].[Amount], [MIDI].[CTLoad_MIDIHolding].[IsOnline], [MIDI].[CTLoad_MIDIHolding].[IsRefund], [MIDI].[CTLoad_MIDIHolding].[OriginatorID], [MIDI].[CTLoad_MIDIHolding].[MCCID], [MIDI].[CTLoad_MIDIHolding].[PostStatusID], [MIDI].[CTLoad_MIDIHolding].[LocationID], [MIDI].[CTLoad_MIDIHolding].[ConsumerCombinationID]
	, [MIDI].[CTLoad_MIDIHolding].[SecondaryCombinationID], [MIDI].[CTLoad_MIDIHolding].[InputModeID], [MIDI].[CTLoad_MIDIHolding].[PaymentTypeID])
SELECT [MIDI].[CTLoad_InitialStage].[FileID], [MIDI].[CTLoad_InitialStage].[RowNum], [MIDI].[CTLoad_InitialStage].[BankID], [MIDI].[CTLoad_InitialStage].[MID], [MIDI].[CTLoad_InitialStage].[Narrative], [MIDI].[CTLoad_InitialStage].[LocationAddress], [MIDI].[CTLoad_InitialStage].[LocationCountry], [MIDI].[CTLoad_InitialStage].[CardholderPresentData], [MIDI].[CTLoad_InitialStage].[TranDate]
	, [MIDI].[CTLoad_InitialStage].[CINID], [MIDI].[CTLoad_InitialStage].[Amount], [MIDI].[CTLoad_InitialStage].[IsOnline], [MIDI].[CTLoad_InitialStage].[IsRefund], [MIDI].[CTLoad_InitialStage].[OriginatorID], [MIDI].[CTLoad_InitialStage].[MCCID], [MIDI].[CTLoad_InitialStage].[PostStatusID], LocationID = 0, [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID]
	, [MIDI].[CTLoad_InitialStage].[SecondaryCombinationID], [MIDI].[CTLoad_InitialStage].[InputModeID], [MIDI].[CTLoad_InitialStage].[PaymentTypeID]
FROM MIDI.CTLoad_InitialStage
WHERE [MIDI].[CTLoad_InitialStage].[CINID] IS NOT NULL
	--AND (ConsumerCombinationID IS NULL OR LocationID IS NULL)
	AND ([MIDI].[CTLoad_InitialStage].[ConsumerCombinationID] IS NULL)
-- (249,905 rows affected) / 00:00:03
SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture remaining matchable transactions for manual processing [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


UPDATE p SET 
	[p].[RowsProcessed] = ISNULL([p].[RowsProcessed],0) + ISNULL(@RowsAffected,0),
	[p].[ProcessedDate] = GETDATE()  
FROM MIDI.GenericTrans_FilesProcessed p
INNER JOIN (SELECT [MIDI].[CTLoad_InitialStage].[FileID] FROM MIDI.CTLoad_InitialStage GROUP BY [MIDI].[CTLoad_InitialStage].[FileID]) s ON s.FileID = p.FileID


-- loop step [QA Logging] EXEC gas.CTLoad_QAStats_Set 
INSERT INTO MIDI.CardTransaction_QA ([MIDI].[CardTransaction_QA].[FileID], [MIDI].[CardTransaction_QA].[FileCount], [MIDI].[CardTransaction_QA].[MatchedCount], [MIDI].[CardTransaction_QA].[UnmatchedCount], [MIDI].[CardTransaction_QA].[NoCINCount], [MIDI].[CardTransaction_QA].[PositiveCount])
SELECT [MIDI].[CTLoad_InitialStage].[FileID]
	, COUNT(1) AS FileCount
	, SUM(CASE WHEN [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID] IS NULL THEN 0 ELSE 1 END) AS MatchedCount
	, SUM(CASE WHEN [MIDI].[CTLoad_InitialStage].[ConsumerCombinationID] IS NULL THEN 1 ELSE 0 END) AS UnmatchedCount
	, SUM(CASE WHEN [MIDI].[CTLoad_InitialStage].[CINID] IS NULL THEN 0 ELSE 1 END) AS NoCINCount
	, SUM(CASE WHEN [MIDI].[CTLoad_InitialStage].[IsRefund] = 0 THEN 1 ELSE 0 END) AS PositiveCount
FROM MIDI.CTLoad_InitialStage
GROUP BY [MIDI].[CTLoad_InitialStage].[FileID]
-- (1 row affected) / 00:00:01


TRUNCATE TABLE MIDI.CTLoad_InitialStage

SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - End of second part'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

RETURN 0 


