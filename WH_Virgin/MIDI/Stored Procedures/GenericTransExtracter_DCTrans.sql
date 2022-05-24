--=====================================================================================================
-- This is just a simple program to pull data from a source table into a generic destination table which 
-- is then used as the source of data for the rest of the MIDI process
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
											,	[TranDate]
											,	[TranTime]
											,	[Amount]
											,	[CurrencyCode]
											,	[CardInputMode]
											,	[CashbackAmount]
											,	[IsOnline]
											,	[IsRefund])
SELECT	ftp.FileID
	,	RowNum = ROW_NUMBER() OVER (PARTITION BY ftp.FileID ORDER BY tr.TransactionDate, tr.TransactionTime, tr.Amount, tr.CardID)
	,	ftp.FileName
	,	tr.LoadDate
	,	tr.CardID
	,	MerchantID = LTRIM(RTRIM(tr.MerchantID))
	,	MerchantCountry = LTRIM(RTRIM(tr.MerchantCountry))
	,	MerchantName = LTRIM(RTRIM(tr.MerchantName))
	,	tr.CardholderPresent
	,	tr.MerchantClassCode
	,	tr.TransactionDate
	,	tr.TransactionTime
	,	tr.Amount
	,	CurrencyCode = LTRIM(RTRIM(tr.CurrencyCode))
	,	tr.CardInputMode
	,	tr.CashbackAmount
	
	,	IsOnline = CASE WHEN tr.CardholderPresent = 5 THEN 1 ELSE 0 END
	,	IsRefund = CASE WHEN Amount < 0 THEN 1 ELSE 0 END
FROM [Inbound].[Transactions] tr
INNER JOIN #FilesToProcess ftp
	ON tr.FileName = ftp.FileName
	AND CONVERT(DATE, tr.LoadDate) = CONVERT(DATE, ftp.LoadDate)
ORDER BY	ftp.FileID
		,	RowNum

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
	ON cis.MerchantCountry = cc.Alpha3Code

UPDATE cis
SET cis.MerchantCountry = 'RO'
FROM [MIDI].[CTLoad_InitialStage] cis
WHERE cis.MerchantCountry = 'ROM'

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
