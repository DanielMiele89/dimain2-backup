CREATE PROCEDURE [dbo].[MigrationCheck_MIDI_ConsumerCombination] AS 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RowCount BIGINT

IF OBJECT_ID('tempdb..#ConsumerCombinationDIMAIN2') IS NOT NULL DROP TABLE #ConsumerCombinationDIMAIN2;
SELECT ConsumerCombinationID, [hash] = CHECKSUM(
	--[BrandMIDID]
      --,[BrandID],
	  [MID],[Narrative],[LocationCountry],[MCCID],[OriginatorID],[IsHighVariance],[IsUKSpend],[PaymentGatewayStatusID],[IsCreditOrigin]) 
INTO #ConsumerCombinationDIMAIN2
FROM Warehouse.relational.ConsumerCombination
SET @RowCount = @@ROWCOUNT
CREATE UNIQUE CLUSTERED INDEX ucx_ConsumerCombinationID ON #ConsumerCombinationDIMAIN2 (ConsumerCombinationID)
-- (31733812 rows affected) / 00:05:03

IF OBJECT_ID('tempdb..#ConsumerCombinationDIDEVTEST') IS NOT NULL DROP TABLE #ConsumerCombinationDIDEVTEST;
SELECT ConsumerCombinationID, [hash] 
INTO #ConsumerCombinationDIDEVTEST 
FROM OPENQUERY (DIDEVTEST, 'SELECT ConsumerCombinationID, [hash] = CHECKSUM(
	--[BrandMIDID]
      --,[BrandID],
	  [MID],[Narrative],[LocationCountry],[MCCID],[OriginatorID],[IsHighVariance],[IsUKSpend],[PaymentGatewayStatusID],[IsCreditOrigin]) 
	  FROM Warehouse.relational.ConsumerCombination')
CREATE UNIQUE CLUSTERED INDEX ucx_ConsumerCombinationID ON #ConsumerCombinationDIDEVTEST (ConsumerCombinationID)
-- (31733812 rows affected) / 00:06:05

IF OBJECT_ID('tempdb..#ConsumerCombinationDIMAIN') IS NOT NULL DROP TABLE #ConsumerCombinationDIMAIN;
SELECT ConsumerCombinationID, [hash] 
INTO #ConsumerCombinationDIMAIN 
FROM OPENQUERY (DIMAIN, 'SELECT ConsumerCombinationID, [hash] = CHECKSUM(
	--[BrandMIDID]
      --,[BrandID],
	  [MID],[Narrative],[LocationCountry],[MCCID],[OriginatorID],[IsHighVariance],[IsUKSpend],[PaymentGatewayStatusID],[IsCreditOrigin]) 
	  FROM Warehouse.relational.ConsumerCombination')
CREATE UNIQUE CLUSTERED INDEX ucx_ConsumerCombinationID ON #ConsumerCombinationDIMAIN (ConsumerCombinationID)
-- (31733812 rows affected) / 00:17:07


SELECT TableName = 'Relational.ConsumerCombination', [Date] = GETDATE(), [RowCount] = @RowCount

;WITH NewRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT ConsumerCombinationID FROM #ConsumerCombinationDIDEVTEST EXCEPT SELECT ConsumerCombinationID FROM #ConsumerCombinationDIMAIN2) d -- 0
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT ConsumerCombinationID FROM #ConsumerCombinationDIMAIN2 EXCEPT SELECT ConsumerCombinationID FROM #ConsumerCombinationDIDEVTEST) d -- 0
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT ConsumerCombinationID FROM #ConsumerCombinationDIMAIN EXCEPT SELECT ConsumerCombinationID FROM #ConsumerCombinationDIDEVTEST) d -- 0
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT ConsumerCombinationID FROM #ConsumerCombinationDIDEVTEST EXCEPT SELECT ConsumerCombinationID FROM #ConsumerCombinationDIMAIN) d -- 0
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT ConsumerCombinationID FROM #ConsumerCombinationDIMAIN2 EXCEPT SELECT ConsumerCombinationID FROM #ConsumerCombinationDIMAIN) d -- 0
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT ConsumerCombinationID FROM #ConsumerCombinationDIMAIN EXCEPT SELECT ConsumerCombinationID FROM #ConsumerCombinationDIMAIN2) d -- 0
), ChangedRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT [hash] FROM #ConsumerCombinationDIDEVTEST EXCEPT SELECT [hash] FROM #ConsumerCombinationDIMAIN2) d -- 17
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT [hash] FROM #ConsumerCombinationDIMAIN2 EXCEPT SELECT [hash] FROM #ConsumerCombinationDIDEVTEST) d -- 17
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT [hash] FROM #ConsumerCombinationDIMAIN EXCEPT SELECT [hash] FROM #ConsumerCombinationDIDEVTEST) d -- 311
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT [hash] FROM #ConsumerCombinationDIDEVTEST EXCEPT SELECT [hash] FROM #ConsumerCombinationDIMAIN) d -- 311
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT [hash] FROM #ConsumerCombinationDIMAIN2 EXCEPT SELECT [hash] FROM #ConsumerCombinationDIMAIN) d -- 296
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT [hash] FROM #ConsumerCombinationDIMAIN EXCEPT SELECT [hash] FROM #ConsumerCombinationDIMAIN2) d -- 296
)
SELECT n.[Description], n.[RowCount] AS [New rows], c.[RowCount]-n.[RowCount] AS [Changed Rows]
FROM NewRows n
INNER JOIN ChangedRows c 
	ON c.[Description] = n.[Description]
-- 6 / 00:04:58


RETURN 0

