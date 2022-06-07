CREATE PROCEDURE [dbo].[MigrationCheck_WHB_CBP_CustomerSpend] AS 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RowCount BIGINT


IF 1 = 1 BEGIN
	IF OBJECT_ID('tempdb..#CustomerDIMAIN2') IS NOT NULL DROP TABLE #CustomerDIMAIN2;
	SELECT FanID, PaymentMethodID, [hash] = CHECKSUM(FanID, PaymentMethodID, TransCount, TransAmount) 
	INTO #CustomerDIMAIN2
	FROM Warehouse.MI.CBP_CustomerSpend
	SET @RowCount = @@ROWCOUNT
	CREATE UNIQUE CLUSTERED INDEX ucx_FanID ON #CustomerDIMAIN2 (FanID, PaymentMethodID)
	-- (7355323 rows affected) / 00:00:15

	IF OBJECT_ID('tempdb..#CustomerDIDEVTEST') IS NOT NULL DROP TABLE #CustomerDIDEVTEST;
	SELECT FanID, PaymentMethodID, [hash] 
	INTO #CustomerDIDEVTEST 
	FROM OPENQUERY (DIDEVTEST, 'SELECT FanID, PaymentMethodID, [hash] = CHECKSUM(FanID, PaymentMethodID, TransCount, TransAmount) FROM Warehouse.MI.CBP_CustomerSpend')
	CREATE UNIQUE CLUSTERED INDEX ucx_FanID ON #CustomerDIDEVTEST (FanID, PaymentMethodID)
	-- (7355323 rows affected) / 00:00:15

	IF OBJECT_ID('tempdb..#CustomerDIMAIN') IS NOT NULL DROP TABLE #CustomerDIMAIN;
	SELECT FanID, PaymentMethodID, [hash] 
	INTO #CustomerDIMAIN 
	FROM OPENQUERY (DIMAIN, 'SELECT FanID, PaymentMethodID, [hash] = CHECKSUM(FanID, PaymentMethodID, TransCount, TransAmount) FROM Warehouse.MI.CBP_CustomerSpend')
	CREATE UNIQUE CLUSTERED INDEX ucx_FanID ON #CustomerDIMAIN (FanID, PaymentMethodID)
	-- (7355323 rows affected) / 00:00:15
END
-- 00:01:23

SELECT TableName = 'MI.CBP_CustomerSpend', [Date] = GETDATE(), [RowCount] = @RowCount

;WITH NewRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT FanID, PaymentMethodID FROM #CustomerDIDEVTEST EXCEPT SELECT FanID, PaymentMethodID FROM #CustomerDIMAIN2) d -- 0
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT FanID, PaymentMethodID FROM #CustomerDIMAIN2 EXCEPT SELECT FanID, PaymentMethodID FROM #CustomerDIDEVTEST) d -- 0
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT FanID, PaymentMethodID FROM #CustomerDIMAIN EXCEPT SELECT FanID, PaymentMethodID FROM #CustomerDIDEVTEST) d -- 0
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT FanID, PaymentMethodID FROM #CustomerDIDEVTEST EXCEPT SELECT FanID, PaymentMethodID FROM #CustomerDIMAIN) d -- 0
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT FanID, PaymentMethodID FROM #CustomerDIMAIN2 EXCEPT SELECT FanID, PaymentMethodID FROM #CustomerDIMAIN) d -- 0
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT FanID, PaymentMethodID FROM #CustomerDIMAIN EXCEPT SELECT FanID, PaymentMethodID FROM #CustomerDIMAIN2) d -- 0
), ChangedRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT * FROM #CustomerDIDEVTEST EXCEPT SELECT * FROM #CustomerDIMAIN2) d -- 17
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT * FROM #CustomerDIMAIN2 EXCEPT SELECT * FROM #CustomerDIDEVTEST) d -- 17
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT * FROM #CustomerDIMAIN EXCEPT SELECT * FROM #CustomerDIDEVTEST) d -- 311
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT * FROM #CustomerDIDEVTEST EXCEPT SELECT * FROM #CustomerDIMAIN) d -- 311
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT * FROM #CustomerDIMAIN2 EXCEPT SELECT * FROM #CustomerDIMAIN) d -- 296
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT * FROM #CustomerDIMAIN EXCEPT SELECT * FROM #CustomerDIMAIN2) d -- 296
)
SELECT n.[Description], n.[RowCount] AS [New rows], c.[RowCount]-n.[RowCount] AS [Changed Rows]
FROM NewRows n
INNER JOIN ChangedRows c 
	ON c.[Description] = n.[Description]
-- 6 / 00:03:04


RETURN 0

