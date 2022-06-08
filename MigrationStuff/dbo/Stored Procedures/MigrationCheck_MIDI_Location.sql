CREATE PROCEDURE [MigrationCheck_MIDI_Location] AS 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RowCount BIGINT

IF OBJECT_ID('tempdb..#LocationDIMAIN2') IS NOT NULL DROP TABLE #LocationDIMAIN2;
SELECT LocationID, [hash] = CHECKSUM([ConsumerCombinationID],[LocationAddress],[IsNonLocational]) 
INTO #LocationDIMAIN2
FROM Warehouse.relational.Location
SET @RowCount = @@ROWCOUNT
CREATE UNIQUE CLUSTERED INDEX ucx_LocationID ON #LocationDIMAIN2 (LocationID)
-- (35,410,392 rows affected) / 00:00:54

IF OBJECT_ID('tempdb..#LocationDIDEVTEST') IS NOT NULL DROP TABLE #LocationDIDEVTEST;
SELECT LocationID, [hash] 
INTO #LocationDIDEVTEST 
FROM OPENQUERY (DIDEVTEST, 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
	SELECT LocationID, [hash] = CHECKSUM([ConsumerCombinationID],[LocationAddress],[IsNonLocational]) FROM Warehouse.relational.Location')
CREATE UNIQUE CLUSTERED INDEX ucx_LocationID ON #LocationDIDEVTEST (LocationID)
-- (35,410,363 rows affected) / 00:00:49

IF OBJECT_ID('tempdb..#LocationDIMAIN') IS NOT NULL DROP TABLE #LocationDIMAIN;
SELECT LocationID, [hash] 
INTO #LocationDIMAIN 
FROM OPENQUERY (DIMAIN, 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SELECT LocationID, [hash] = CHECKSUM([ConsumerCombinationID],[LocationAddress],[IsNonLocational]) FROM Warehouse.relational.Location')
CREATE UNIQUE CLUSTERED INDEX ucx_LocationID ON #LocationDIMAIN (LocationID)
-- (35,410,363 rows affected) / 00:01:43

SELECT TableName = 'Relational.Location', [Date] = GETDATE(), [RowCount] = @RowCount

;WITH NewRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT LocationID FROM #LocationDIDEVTEST EXCEPT SELECT LocationID FROM #LocationDIMAIN2) d -- 0
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT LocationID FROM #LocationDIMAIN2 EXCEPT SELECT LocationID FROM #LocationDIDEVTEST) d -- 0
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT LocationID FROM #LocationDIMAIN EXCEPT SELECT LocationID FROM #LocationDIDEVTEST) d -- 0
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT LocationID FROM #LocationDIDEVTEST EXCEPT SELECT LocationID FROM #LocationDIMAIN) d -- 0
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT LocationID FROM #LocationDIMAIN2 EXCEPT SELECT LocationID FROM #LocationDIMAIN) d -- 0
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT LocationID FROM #LocationDIMAIN EXCEPT SELECT LocationID FROM #LocationDIMAIN2) d -- 0
), ChangedRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT [hash] FROM #LocationDIDEVTEST EXCEPT SELECT [hash] FROM #LocationDIMAIN2) d -- 17
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT [hash] FROM #LocationDIMAIN2 EXCEPT SELECT [hash] FROM #LocationDIDEVTEST) d -- 17
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT [hash] FROM #LocationDIMAIN EXCEPT SELECT [hash] FROM #LocationDIDEVTEST) d -- 311
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT [hash] FROM #LocationDIDEVTEST EXCEPT SELECT [hash] FROM #LocationDIMAIN) d -- 311
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT [hash] FROM #LocationDIMAIN2 EXCEPT SELECT [hash] FROM #LocationDIMAIN) d -- 296
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT [hash] FROM #LocationDIMAIN EXCEPT SELECT [hash] FROM #LocationDIMAIN2) d -- 296
)
SELECT n.[Description], n.[RowCount] AS [New rows], c.[RowCount]-n.[RowCount] AS [Changed Rows]
FROM NewRows n
INNER JOIN ChangedRows c 
	ON c.[Description] = n.[Description]
-- 6 / 00:06:38


RETURN 0

