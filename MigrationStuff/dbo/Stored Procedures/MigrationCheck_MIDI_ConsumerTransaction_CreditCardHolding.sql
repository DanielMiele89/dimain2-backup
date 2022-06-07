CREATE PROCEDURE [dbo].[MigrationCheck_MIDI_ConsumerTransaction_CreditCardHolding] AS 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RowCount BIGINT

IF 1 = 1 BEGIN
	IF OBJECT_ID('tempdb..#ConsumerTransaction_CreditCardHoldingDIMAIN2') IS NOT NULL DROP TABLE #ConsumerTransaction_CreditCardHoldingDIMAIN2;
	SELECT FileID, RowNum, [hash] = CHECKSUM([FileID],[RowNum],[CardholderPresentData],[TranDate],[Amount],[IsOnline],[FanID]) 
	INTO #ConsumerTransaction_CreditCardHoldingDIMAIN2
	FROM Warehouse.relational.ConsumerTransaction_CreditCardHolding
	SET @RowCount = @@ROWCOUNT
	CREATE UNIQUE CLUSTERED INDEX ucx_FileID_RowNum ON #ConsumerTransaction_CreditCardHoldingDIMAIN2 (FileID, RowNum)
	-- (1628064 rows affected) / 00:00:59

	IF OBJECT_ID('tempdb..#ConsumerTransaction_CreditCardHoldingDIDEVTEST') IS NOT NULL DROP TABLE #ConsumerTransaction_CreditCardHoldingDIDEVTEST;
	SELECT FileID, RowNum, [hash] 
	INTO #ConsumerTransaction_CreditCardHoldingDIDEVTEST 
	FROM OPENQUERY (DIDEVTEST, 'SELECT FileID, RowNum, [hash] = CHECKSUM([FileID],[RowNum],[CardholderPresentData],[TranDate],[Amount],[IsOnline],[FanID]) 
		FROM Warehouse.relational.ConsumerTransaction_CreditCardHolding')
	CREATE UNIQUE CLUSTERED INDEX ucx_FileID_RowNum ON #ConsumerTransaction_CreditCardHoldingDIDEVTEST (FileID, RowNum)
	-- (1628064 rows affected) / 00:06:05

	IF OBJECT_ID('tempdb..#ConsumerTransaction_CreditCardHoldingDIMAIN') IS NOT NULL DROP TABLE #ConsumerTransaction_CreditCardHoldingDIMAIN;
	SELECT FileID, RowNum, [hash] 
	INTO #ConsumerTransaction_CreditCardHoldingDIMAIN 
	FROM OPENQUERY (DIMAIN, 'SELECT FileID, RowNum, [hash] = CHECKSUM([FileID],[RowNum],[CardholderPresentData],[TranDate],[Amount],[IsOnline],[FanID]) 
		FROM Warehouse.relational.ConsumerTransaction_CreditCardHolding')
	CREATE UNIQUE CLUSTERED INDEX ucx_FileID_RowNum ON #ConsumerTransaction_CreditCardHoldingDIMAIN (FileID, RowNum)
	-- (1628064 rows affected) / 00:17:07
END
-- 00:35:00

SELECT TableName = 'Relational.ConsumerTransaction_CreditCardHolding', [Date] = GETDATE(), [RowCount] = @RowCount

;WITH NewRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIDEVTEST EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIMAIN2) d -- 0
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIMAIN2 EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIDEVTEST) d -- 0
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIMAIN EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIDEVTEST) d -- 0
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIDEVTEST EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIMAIN) d -- 0
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIMAIN2 EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIMAIN) d -- 0
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIMAIN EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardHoldingDIMAIN2) d -- 0
), ChangedRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIDEVTEST EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIMAIN2) d -- 17
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIMAIN2 EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIDEVTEST) d -- 17
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIMAIN EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIDEVTEST) d -- 311
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIDEVTEST EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIMAIN) d -- 311
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIMAIN2 EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIMAIN) d -- 296
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIMAIN EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardHoldingDIMAIN2) d -- 296
)
SELECT n.[Description], n.[RowCount] AS [New rows], c.[RowCount]-n.[RowCount] AS [Changed Rows]
FROM NewRows n
INNER JOIN ChangedRows c 
	ON c.[Description] = n.[Description]
-- 6 / 00:00:17


RETURN 0


