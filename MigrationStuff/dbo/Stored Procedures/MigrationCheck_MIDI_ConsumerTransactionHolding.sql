CREATE PROCEDURE [dbo].[MigrationCheck_MIDI_ConsumerTransactionHolding] AS 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RowCount BIGINT

IF 1 = 1 BEGIN
	IF OBJECT_ID('tempdb..#ConsumerTransactionHoldingDIMAIN2') IS NOT NULL DROP TABLE #ConsumerTransactionHoldingDIMAIN2;
	SELECT FileID, RowNum, [hash] = CHECKSUM([FileID],[RowNum],[BankID],[CardholderPresentData],[TranDate],[Amount],[IsRefund],[IsOnline],[InputModeID],[PostStatusID],[PaymentTypeID]) 
	INTO #ConsumerTransactionHoldingDIMAIN2
	FROM Warehouse.relational.ConsumerTransactionHolding
	SET @RowCount = @@ROWCOUNT
	CREATE UNIQUE CLUSTERED INDEX ucx_FileID_RowNum ON #ConsumerTransactionHoldingDIMAIN2 (FileID, RowNum)
	-- (53362156 rows affected) / 00:00:59

	IF OBJECT_ID('tempdb..#ConsumerTransactionHoldingDIDEVTEST') IS NOT NULL DROP TABLE #ConsumerTransactionHoldingDIDEVTEST;
	SELECT FileID, RowNum, [hash] 
	INTO #ConsumerTransactionHoldingDIDEVTEST 
	FROM OPENQUERY (DIDEVTEST, 'SELECT FileID, RowNum, [hash] = CHECKSUM([FileID],[RowNum],[BankID],[CardholderPresentData],[TranDate],[Amount],[IsRefund],[IsOnline],[InputModeID],[PostStatusID],[PaymentTypeID]) 
		FROM Warehouse.relational.ConsumerTransactionHolding')
	CREATE UNIQUE CLUSTERED INDEX ucx_FileID_RowNum ON #ConsumerTransactionHoldingDIDEVTEST (FileID, RowNum)
	-- (53362156 rows affected) / 00:06:05

	IF OBJECT_ID('tempdb..#ConsumerTransactionHoldingDIMAIN') IS NOT NULL DROP TABLE #ConsumerTransactionHoldingDIMAIN;
	SELECT FileID, RowNum, [hash] 
	INTO #ConsumerTransactionHoldingDIMAIN 
	FROM OPENQUERY (DIMAIN, 'SELECT FileID, RowNum, [hash] = CHECKSUM([FileID],[RowNum],[BankID],[CardholderPresentData],[TranDate],[Amount],[IsRefund],[IsOnline],[InputModeID],[PostStatusID],[PaymentTypeID]) 
		FROM Warehouse.relational.ConsumerTransactionHolding')
	CREATE UNIQUE CLUSTERED INDEX ucx_FileID_RowNum ON #ConsumerTransactionHoldingDIMAIN (FileID, RowNum)
	-- (53362156 rows affected) / 00:17:07
END
-- 00:16:58

SELECT TableName = 'Relational.ConsumerTransactionHolding', [Date] = GETDATE(), [RowCount] = @RowCount

;WITH NewRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIDEVTEST EXCEPT SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIMAIN2) d -- 0
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIMAIN2 EXCEPT SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIDEVTEST) d -- 0
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIMAIN EXCEPT SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIDEVTEST) d -- 0
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIDEVTEST EXCEPT SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIMAIN) d -- 0
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIMAIN2 EXCEPT SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIMAIN) d -- 0
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIMAIN EXCEPT SELECT FileID, RowNum FROM #ConsumerTransactionHoldingDIMAIN2) d -- 0
), ChangedRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT [hash] FROM #ConsumerTransactionHoldingDIDEVTEST EXCEPT SELECT [hash] FROM #ConsumerTransactionHoldingDIMAIN2) d -- 17
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT [hash] FROM #ConsumerTransactionHoldingDIMAIN2 EXCEPT SELECT [hash] FROM #ConsumerTransactionHoldingDIDEVTEST) d -- 17
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT [hash] FROM #ConsumerTransactionHoldingDIMAIN EXCEPT SELECT [hash] FROM #ConsumerTransactionHoldingDIDEVTEST) d -- 311
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT [hash] FROM #ConsumerTransactionHoldingDIDEVTEST EXCEPT SELECT [hash] FROM #ConsumerTransactionHoldingDIMAIN) d -- 311
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT [hash] FROM #ConsumerTransactionHoldingDIMAIN2 EXCEPT SELECT [hash] FROM #ConsumerTransactionHoldingDIMAIN) d -- 296
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT [hash] FROM #ConsumerTransactionHoldingDIMAIN EXCEPT SELECT [hash] FROM #ConsumerTransactionHoldingDIMAIN2) d -- 296
)
SELECT n.[Description], n.[RowCount] AS [New rows], c.[RowCount]-n.[RowCount] AS [Changed Rows]
FROM NewRows n
INNER JOIN ChangedRows c 
	ON c.[Description] = n.[Description]
-- 6 / 00:05:56


RETURN 0

