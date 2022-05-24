--=====================================================================================================
-- This is just a simple program to pull data from a source table into a generic destination table which 
-- is then used as the source of data for the rest of the MIDI process

-- CJM NOTES for DIMAIN2 (no changes made to this sp)
-- [Inbound].[Transactions] is currently a heap of 32m rows, requires a clustered index on FileName
-- Comment out all the index disable / rebuild
--=====================================================================================================
CREATE PROCEDURE [MIDI].[GenericTransExtracter_DCTrans] AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT


--EXEC gas.CTLoad_FilesToProcess_Fetch

IF OBJECT_ID('tempdb..#FilesToProcess') IS NOT NULL DROP TABLE #FilesToProcess
SELECT	TOP 1
		ID AS FileID
	,	LoadDate
	,	FileName
INTO #FilesToProcess
FROM [WHB].[Inbound_Files] f
WHERE TableName = 'Transactions'
AND FileProcessed = 0
ORDER BY ID

SET @RowsAffected = @@ROWCOUNT


IF @RowsAffected = 0 BEGIN
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - No rows to process'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	RETURN 0
END

DECLARE @WorkWithFile VARCHAR(15) = (SELECT CONVERT(VARCHAR(15), FileID ,105) FROM #FilesToProcess)
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Starting extract for file - [' + @WorkWithFile + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

------------------------------------------------------
-- Debit Card Transaction Processing Loop over #FilesToProcess
------------------------------------------------------

-- disable the ordinary index until it's required
ALTER INDEX IX_MerchantCountry ON [MIDI].[CTLoad_InitialStage] DISABLE
ALTER INDEX IX_MCC ON [MIDI].[CTLoad_InitialStage] DISABLE
ALTER INDEX IX_CardID ON [MIDI].[CTLoad_InitialStage] DISABLE
ALTER INDEX IX_CardIDBankCIN ON [MIDI].[CTLoad_InitialStage] DISABLE
ALTER INDEX IX_CIN ON [MIDI].[CTLoad_InitialStage] DISABLE
ALTER INDEX IX_CardInputMode ON [MIDI].[CTLoad_InitialStage] DISABLE
ALTER INDEX IX_MID ON [MIDI].[CTLoad_InitialStage] DISABLE
ALTER INDEX IX_MIDCountryMCCIDMerchantName ON [MIDI].[CTLoad_InitialStage] DISABLE
ALTER INDEX IX_CCID ON [MIDI].[CTLoad_InitialStage] DISABLE

-- loop step [Load CTLoad_InitialStage]
TRUNCATE TABLE [MIDI].[CTLoad_InitialStage]
INSERT INTO [MIDI].[CTLoad_InitialStage] (	[FileID]
											,	[RowNum]
											,	[FileName]
											,	[LoadDate]
											,	[CardID]
											,	[MID]
											,	[MerchantCountry]
											,	[MerchantName]
											,	[CardholderPresentData]
											,	[MCC]
											,	[MerchantAcquirerBin]
											,	[TranDate]
											,	[TranTime]
											,	[Amount]
											,	[CurrencyCode]
											,	[CardInputMode]
											,	[InputModeID]
											,	[CashbackAmount]
											,	[IsOnline]
											,	[IsRefund])
SELECT	DISTINCT
		ftp.FileID
	,	RowNum = ROW_NUMBER() OVER (ORDER BY tr.TransactionID)
	,	ftp.FileName
	,	tr.LoadDate
	,	tr.CardGUID
	,	MerchantID = LTRIM(RTRIM(tr.MerchantID))
	,	MerchantCountry = LTRIM(RTRIM(tr.MerchantCountry))
	,	MerchantName = LTRIM(RTRIM(tr.MerchantName))
	,	COALESCE(tr.CardholderPresent, 9)
	,	tr.MerchantCategoryCode
	,	tr.MerchantAcquirerBin
	,	tr.TransactionDate
	,	tr.TransactionTime
	,	tr.Amount
	,	CurrencyCode = LTRIM(RTRIM(tr.CurrencyCode))
	,	tr.CardInputMode
	,	0 AS InputModeID
	,	NULL
	
	,	IsOnline = CASE WHEN tr.CardholderPresent = 5 THEN 1 ELSE 0 END
	,	IsRefund = CASE WHEN Amount < 0 THEN 1 ELSE 0 END
FROM [Inbound].[Transactions] tr
INNER JOIN #FilesToProcess ftp
	ON tr.FileName = ftp.FileName
	AND CONVERT(DATE, tr.LoadDate) = CONVERT(DATE, ftp.LoadDate)
--WHERE NOT EXISTS (	SELECT 1
--					FROM [MIDI].[ConsumerTransactionHolding] ct
--					WHERE tr.TransactionID = ct.RowNum)
--AND NOT EXISTS (	SELECT 1
--					FROM [MIDI].CTLoad_MIDIHolding ct
--					WHERE tr.TransactionID = ct.RowNum)
--AND NOT EXISTS (	SELECT 1
--					FROM [Trans].[ConsumerTransaction] ct
--					WHERE tr.TransactionID = ct.RowNum)

SET @RowsAffected = @@ROWCOUNT


ALTER INDEX IX_MerchantCountry ON [MIDI].[CTLoad_InitialStage] REBUILD
ALTER INDEX IX_MCC ON [MIDI].[CTLoad_InitialStage] REBUILD
ALTER INDEX IX_CardID ON [MIDI].[CTLoad_InitialStage] REBUILD
ALTER INDEX IX_CardIDBankCIN ON [MIDI].[CTLoad_InitialStage] REBUILD
ALTER INDEX IX_CIN ON [MIDI].[CTLoad_InitialStage] REBUILD
ALTER INDEX IX_CardInputMode ON [MIDI].[CTLoad_InitialStage] REBUILD
ALTER INDEX IX_MID ON [MIDI].[CTLoad_InitialStage] REBUILD
ALTER INDEX IX_MIDCountryMCCIDMerchantName ON [MIDI].[CTLoad_InitialStage] REBUILD
ALTER INDEX IX_CCID ON [MIDI].[CTLoad_InitialStage] REBUILD

UPDATE cis
SET cis.MerchantCountry = cc.Alpha2Code
FROM [MIDI].[CTLoad_InitialStage] cis
INNER JOIN [Warehouse].[Relational].[CountryCodes_ISO_2] cc
	ON  cc.NumericCode = RIGHT('00' + cis.MerchantCountry, 3)

ALTER INDEX IX_MerchantCountry ON [MIDI].[CTLoad_InitialStage] REBUILD
ALTER INDEX IX_MIDCountryMCCIDMerchantName ON [MIDI].[CTLoad_InitialStage] REBUILD

-- (7426003 rows affected) / 00:02:28

-- Log it

MERGE [MIDI].[GenericTrans_FilesProcessed] target	-- Destination table
USING #FilesToProcess source						-- Source table
ON target.FileID = source.FileID					-- Match criteria
AND target.LoadDate = source.LoadDate

WHEN MATCHED THEN
	UPDATE SET	target.RowsImported = @RowsAffected	-- If matched, update to new value
			,	target.ImportedDate = GETDATE()		-- If matched, update to new value

WHEN NOT MATCHED THEN			-- If not matched, add new rows
	INSERT (FileID
		,	LoadDate
		,	RowsImported
		,	ImportedDate)
	VALUES (source.FileID
		,	source.LoadDate
		,	@RowsAffected
		,	GETDATE());

--OUTPUT $action, inserted.*; -- Output inserted and updated rows

SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Retrieved ' + CAST(@RowsAffected AS VARCHAR(10)) + ' rows from Archive';

EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

RETURN 0

TRUNCATE TABLE [MIDI].[GenericTrans_FilesProcessed]