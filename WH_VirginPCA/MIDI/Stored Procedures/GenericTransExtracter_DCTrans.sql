--=====================================================================================================
-- This is just a simple program to pull data from a source table into a generic destination table which 
-- is then used as the source of data for the rest of the MIDI process
--=====================================================================================================
CREATE PROCEDURE [MIDI].[GenericTransExtracter_DCTrans] AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT

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

-- loop step [Load CTLoad_InitialStage]
TRUNCATE TABLE [MIDI].[CTLoad_InitialStage]
INSERT INTO [MIDI].[CTLoad_InitialStage] (	[TransactionID]
										,	[FileID]
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
		tr.TransactionID
	,	ftp.FileID
	,	RowNum = ROW_NUMBER() OVER (ORDER BY tr.TransactionID)
	,	ftp.FileName
	,	tr.LoadDate
	,	tr.CardGUID
	,	MerchantID = LTRIM(RTRIM(tr.MerchantID))
	,	MerchantCountry = LTRIM(RTRIM(tr.MerchantCountry))
	,	MerchantName =	CASE
							WHEN mn3.MerchantName LIKE '%, ___ %, Rate %, Fee %' THEN SUBSTRING(mn3.MerchantName, 0, PATINDEX('%, ___ %, Rate %, Fee %', mn3.MerchantName))
							ELSE mn3.MerchantName
						END
	,	CardholderPresent = 9
	,	tr.MerchantCategoryCode
	,	MerchantAcquirerBin = NULL
	,	tr.TransactionDate
	,	tr.TransactionTime
	,	tr.Amount
	,	CurrencyCode = LTRIM(RTRIM(tr.CurrencyCode))
	,	tr.CardInputMode
	,	0 AS InputModeID
	,	NULL	
	,	IsOnline = CASE WHEN tr.CardInputMode IN ('eCommerce', 'eCommerce') THEN 1 ELSE 0 END
	,	IsRefund = CASE WHEN Amount < 0 THEN 1 ELSE 0 END
FROM [Inbound].[Transactions] tr
CROSS APPLY (	SELECT	MerchantName =	CASE
											WHEN tr.Narrative LIKE '%""%' THEN REPLACE(tr.Narrative, '""', '"')
											ELSE LTRIM(RTRIM(tr.Narrative))
										END) mn1
CROSS APPLY (	SELECT	MerchantName =	CASE
											WHEN LEFT(mn1.MerchantName, 1) = '"' AND RIGHT(mn1.MerchantName, 1) = '"' THEN LTRIM(RTRIM(SUBSTRING(mn1.MerchantName, 2, LEN(mn1.MerchantName) - 2)))
											ELSE LTRIM(RTRIM(mn1.MerchantName))
										END) mn2
CROSS APPLY (	SELECT	MerchantName =	CASE

											WHEN mn2.MerchantName LIKE 'CLS[0-9][0-9]%' THEN LTRIM(RTRIM(SUBSTRING(mn2.MerchantName, 6, 99999)))
											WHEN mn2.MerchantName LIKE 'CRD[0-9][0-9]%' THEN LTRIM(RTRIM(SUBSTRING(mn2.MerchantName, 6, 99999)))
											WHEN mn2.MerchantName LIKE 'WLT[0-9][0-9]%' THEN LTRIM(RTRIM(SUBSTRING(mn2.MerchantName, 6, 99999)))
							
											WHEN mn2.MerchantName LIKE 'CLS%[0-9][0-9],%' THEN LTRIM(RTRIM(SUBSTRING(mn2.MerchantName, 9, 99999)))
											WHEN mn2.MerchantName LIKE 'Card%[0-9][0-9],%' THEN LTRIM(RTRIM(SUBSTRING(mn2.MerchantName, 9, 99999)))
											WHEN mn2.MerchantName LIKE 'WLT%[0-9][0-9],%' THEN LTRIM(RTRIM(SUBSTRING(mn2.MerchantName, 9, 99999)))

											ELSE LTRIM(RTRIM(mn2.MerchantName))

										END) mn3
INNER JOIN #FilesToProcess ftp
	ON tr.FileName = ftp.FileName
	AND CONVERT(DATE, tr.LoadDate) = CONVERT(DATE, ftp.LoadDate)
WHERE NOT EXISTS (	SELECT 1
					FROM [MIDI].[ProcessedTransactionIDs] pti
					WHERE tr.TransactionID = pti.TransactionID)


SET @RowsAffected = @@ROWCOUNT

UPDATE cis
SET cis.MerchantCountry = cc.Alpha2Code
FROM [MIDI].[CTLoad_InitialStage] cis
INNER JOIN [Warehouse].[Relational].[CountryCodes_ISO_2] cc
	ON  cc.NumericCode = RIGHT('00' + cis.MerchantCountry, 3)

ALTER INDEX IX_MerchantCountry ON [MIDI].[CTLoad_InitialStage] REBUILD

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







