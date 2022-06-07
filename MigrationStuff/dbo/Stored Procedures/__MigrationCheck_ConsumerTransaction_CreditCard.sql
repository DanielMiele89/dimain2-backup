CREATE PROCEDURE [dbo].[__MigrationCheck_ConsumerTransaction_CreditCard] AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RowCount BIGINT

IF 1 = 1 BEGIN
	IF OBJECT_ID('tempdb..#ConsumerTransaction_CreditCardDIMAIN2') IS NOT NULL DROP TABLE #ConsumerTransaction_CreditCardDIMAIN2;
	SELECT FileID, RowNum, [hash] = CHECKSUM(*) 
	INTO #ConsumerTransaction_CreditCardDIMAIN2
	FROM Warehouse.relational.ConsumerTransaction_CreditCard
	SET @RowCount = @@ROWCOUNT
	CREATE UNIQUE CLUSTERED INDEX ucx_FileID_RowNum ON #ConsumerTransaction_CreditCardDIMAIN2 (FileID, RowNum)
	-- (408251570 rows affected) / 00:00:59

	IF OBJECT_ID('tempdb..#ConsumerTransaction_CreditCardDIDEVTEST') IS NOT NULL DROP TABLE #ConsumerTransaction_CreditCardDIDEVTEST;
	SELECT FileID, RowNum, [hash] 
	INTO #ConsumerTransaction_CreditCardDIDEVTEST 
	FROM OPENQUERY (DIDEVTEST, 'SELECT FileID, RowNum, [hash] = CHECKSUM(*) FROM Warehouse.relational.ConsumerTransaction_CreditCard')
	CREATE UNIQUE CLUSTERED INDEX ucx_FileID_RowNum ON #ConsumerTransaction_CreditCardDIDEVTEST (FileID, RowNum)
	-- (408251570 rows affected) / 00:06:05

	IF OBJECT_ID('tempdb..#ConsumerTransaction_CreditCardDIMAIN') IS NOT NULL DROP TABLE #ConsumerTransaction_CreditCardDIMAIN;
	SELECT FileID, RowNum, [hash] 
	INTO #ConsumerTransaction_CreditCardDIMAIN 
	FROM OPENQUERY (DIMAIN, 'SELECT FileID, RowNum, [hash] = CHECKSUM(*) FROM Warehouse.relational.ConsumerTransaction_CreditCard')
	CREATE UNIQUE CLUSTERED INDEX ucx_FileID_RowNum ON #ConsumerTransaction_CreditCardDIMAIN (FileID, RowNum)
	-- (408251570 rows affected) / 00:17:07
END
-- 00:35:00

SELECT TableName = 'Relational.ConsumerTransaction_CreditCard', [Date] = GETDATE(), [RowCount] = @RowCount

;WITH NewRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIDEVTEST EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIMAIN2) d -- 0
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIMAIN2 EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIDEVTEST) d -- 0
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIMAIN EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIDEVTEST) d -- 0
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIDEVTEST EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIMAIN) d -- 0
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIMAIN2 EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIMAIN) d -- 0
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIMAIN EXCEPT SELECT FileID, RowNum FROM #ConsumerTransaction_CreditCardDIMAIN2) d -- 0
), ChangedRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardDIDEVTEST EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardDIMAIN2) d -- 17
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardDIMAIN2 EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardDIDEVTEST) d -- 17
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardDIMAIN EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardDIDEVTEST) d -- 311
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardDIDEVTEST EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardDIMAIN) d -- 311
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardDIMAIN2 EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardDIMAIN) d -- 296
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT * FROM #ConsumerTransaction_CreditCardDIMAIN EXCEPT SELECT * FROM #ConsumerTransaction_CreditCardDIMAIN2) d -- 296
)
SELECT n.[Description], n.[RowCount] AS [New rows], c.[RowCount]-n.[RowCount] AS [Changed Rows]
FROM NewRows n
INNER JOIN ChangedRows c 
	ON c.[Description] = n.[Description]
-- 6 / 00:51:35


RETURN 0



