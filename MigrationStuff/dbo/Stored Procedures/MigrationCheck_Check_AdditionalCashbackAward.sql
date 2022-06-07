CREATE PROCEDURE [dbo].[MigrationCheck_Check_AdditionalCashbackAward] AS 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RowCount BIGINT


IF 1 = 1 BEGIN
	IF OBJECT_ID('tempdb..#CustomerDIMAIN2') IS NOT NULL DROP TABLE #CustomerDIMAIN2;
	SELECT FileID, MatchID = CASE WHEN MatchID IS NULL THEN 'NULL' ELSE 'NOT NULL' END, cnt = COUNT(*) INTO #CustomerDIMAIN2 
	FROM Warehouse.Relational.AdditionalCashbackAward WHERE FileID > 34204 GROUP BY FileID, CASE WHEN MatchID IS NULL THEN 'NULL' ELSE 'NOT NULL' END
	SET @RowCount = @@ROWCOUNT
	-- (82 rows affected) / 00:00:23

	IF OBJECT_ID('tempdb..#CustomerDIDEVTEST') IS NOT NULL DROP TABLE #CustomerDIDEVTEST;
	SELECT FileID, MatchID = CASE WHEN MatchID IS NULL THEN 'NULL' ELSE 'NOT NULL' END, CNT = COUNT(*) INTO #CustomerDIDEVTEST 
	FROM DIDEVTEST.Warehouse.Relational.AdditionalCashbackAward WHERE FileID > 34204 GROUP BY FileID, CASE WHEN MatchID IS NULL THEN 'NULL' ELSE 'NOT NULL' END
	-- (82 rows affected) / 00:00:07

	IF OBJECT_ID('tempdb..#CustomerDIMAIN') IS NOT NULL DROP TABLE #CustomerDIMAIN;
	SELECT FileID, MatchID = CASE WHEN MatchID IS NULL THEN 'NULL' ELSE 'NOT NULL' END, CNT = COUNT(*) INTO #CustomerDIMAIN 
	FROM DIMAIN.Warehouse.Relational.AdditionalCashbackAward WHERE FileID > 34204 GROUP BY FileID, CASE WHEN MatchID IS NULL THEN 'NULL' ELSE 'NOT NULL' END
	-- (82 rows affected) / 00:01:22
END
-- 00:01:23

SELECT TableName = 'Relational.AdditionalCashbackAward', [Date] = GETDATE(), [RowCount] = @RowCount

;WITH Files AS (
	SELECT DISTINCT FileID 
	FROM (SELECT FileID FROM #CustomerDIMAIN2 UNION SELECT FileID FROM #CustomerDIDEVTEST UNION SELECT FileID FROM #CustomerDIDEVTEST) d
)
SELECT f.FileID, n.InDate, x.MatchID, d2.cnt AS [DIMAIN2], di.CNT AS [DIDEVTEST], d.cnt AS [DIMAIN] 
FROM Files f
CROSS JOIN (VALUES('NOT NULL'),('NULL')) x (MatchID)
LEFT JOIN SLC_REPL.dbo.NobleFiles n 
	ON n.ID = f.FileID
LEFT JOIN #CustomerDIMAIN2 d2 
	ON d2.FileID = f.FileID AND d2.MatchID = x.MatchID
LEFT JOIN #CustomerDIDEVTEST di 
	ON di.FileID = f.FileID AND di.MatchID = x.MatchID
LEFT JOIN #CustomerDIMAIN d 
	ON d.FileID = f.FileID AND d.MatchID = x.MatchID
WHERE COALESCE(d2.cnt, di.CNT, d.cnt) IS NOT NULL
ORDER BY f.FileID DESC, x.MatchID


RETURN 0



