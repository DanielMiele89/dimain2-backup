/*

EXEC ('Warehouse.MI.SchemeTransUniqueID_Topup') AT lsDIMAIN
- about 15-20 minutes

Replaces the following procedures as part of LegacyPortal:
[Staging].[SchemeTransUniqueID_Clear]
[MI].[SchemeTransUniqueID_PartnerTrans_Fetch]
[MI].[SchemeTransUniqueID_AdditionalCashback_Fetch]
[MI].[SchemeTransUniqueID_Indexes_Disable]
[Staging].[SchemeTransUniqueID_Fetch]
MI.SchemeTransUniqueID_RemoveDuplicates
[MI].[SchemeTransUniqueID_Indexes_Rebuild]
*/
CREATE procedure [MI].[SchemeTransUniqueID_Topup_DIMAIN]

AS

DECLARE 
	@msg VARCHAR(1000), 
	@time DATETIME = GETDATE(), 
	@SSMS BIT = 1, 
	@RowsAffected BIGINT;

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET @msg = 'Started [MI.SchemeTransUniqueID_Topup]'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

--------------------------------------------------------------
-- [Staging].[SchemeTransUniqueID_Clear] 
--------------------------------------------------------------
TRUNCATE TABLE Staging.SchemeTransUniqueID

-- Can't this be done with a single update query?
UPDATE MI.SchemeTransUniqueID SET MatchID = a.MatchID
FROM MI.SchemeTransUniqueID s
INNER JOIN Relational.AdditionalCashbackAward a ON s.FileID = a.FileID AND s.RowNum = a.RowNum
WHERE a.MatchID IS NOT NULL AND s.MatchID IS NULL;

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished first MatchID update: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Finished first MatchID update: 0 rows  >>>>>  Time Taken: 00:00:56


UPDATE MI.SchemeTransUniqueID SET MatchID = NULL
FROM MI.SchemeTransUniqueID s
INNER JOIN Relational.AdditionalCashbackAward a ON s.FileID = a.FileID AND s.RowNum = a.RowNum
WHERE a.MatchID IS NULL AND s.MatchID IS NOT NULL;

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished second MatchID update: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Finished second MatchID update: 0 rows  >>>>>  Time Taken: 00:03:55


--------------------------------------------------------------
-- [MI].[SchemeTransUniqueID_PartnerTrans_Fetch] 
--------------------------------------------------------------
INSERT INTO Staging.SchemeTransUniqueID (MatchID, FileID, RowNum)
SELECT pt.MatchID, a.FileID, a.RowNum
FROM Relational.PartnerTrans pt 
LEFT OUTER JOIN (
	SELECT DISTINCT MatchID, FileID, RowNum
	FROM Relational.AdditionalCashbackAward a 
	WHERE MatchID IS NOT NULL
) a 
	ON pt.MatchID = a.MatchID
LEFT OUTER JOIN MI.SchemeTransUniqueID s 
	ON pt.MatchID = s.MatchID
WHERE S.MatchID IS NULL;

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Collected PartnerTrans data: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Collected PartnerTrans data: 35303 rows  >>>>>  Time Taken: 00:04:45


--------------------------------------------------------------
-- [MI].[SchemeTransUniqueID_AdditionalCashback_Fetch]
--------------------------------------------------------------
INSERT INTO Staging.SchemeTransUniqueID (MatchID, FileID, RowNum)
SELECT DISTINCT CAST(NULL AS INT) AS MatchID, a.FileID, a.RowNum
FROM Relational.AdditionalCashbackAward a 
LEFT OUTER JOIN MI.SchemeTransUniqueID s  
	ON a.FileID = s.FileID and a.RowNum = s.RowNum
WHERE S.FileID IS NULL and a.MatchID IS NULL;

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Collected AdditionalCashbackAward data: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Collected AdditionalCashbackAward data: 482468 rows  >>>>>  Time Taken: 00:01:47


--------------------------------------------------------------
-- [MI].[SchemeTransUniqueID_Indexes_Disable]
--------------------------------------------------------------
ALTER INDEX IX_MI_SchemeTransUniqueID_MatchID ON MI.SchemeTransUniqueID DISABLE;
ALTER INDEX IX_MI_SchemeTransUniqueID_FileIDRowNum ON MI.SchemeTransUniqueID DISABLE;


--------------------------------------------------------------
-- [Staging].[SchemeTransUniqueID_Fetch]
--------------------------------------------------------------
INSERT INTO [MI].[SchemeTransUniqueID] (MatchID, FileID, RowNum)
SELECT MatchID, FileID, RowNum
FROM Staging.SchemeTransUniqueID;

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Target table topped up: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Target table topped up: 517771 rows  >>>>>  Time Taken: 00:00:16


--------------------------------------------------------------
-- MI.SchemeTransUniqueID_RemoveDuplicates
--------------------------------------------------------------
CREATE TABLE #MatchDuplicate (MatchID INT PRIMARY KEY, MatchCount INT NOT NULL)
CREATE TABLE #FileDuplicate (FileID INT NOT NULL, RowNum INT NOT NULL, MatchCount INT NOT NULL)
ALTER TABLE #FileDuplicate ADD PRIMARY KEY(FileID, RowNum)

INSERT INTO #MatchDuplicate(MatchID, MatchCount)
SELECT MatchID, COUNT(*) AS freq
FROM MI.SchemeTransUniqueID WITH (NOLOCK)
WHERE MatchID IS NOT NULL
GROUP BY MatchID
HAVING COUNT(*) > 1;

DELETE u
FROM MI.SchemeTransUniqueID u
INNER JOIN #MatchDuplicate m ON u.MatchID = m.MatchID
WHERE u.FileID IS NULL;

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Deleted MATCH duplicates: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Deleted MATCH duplicates: 0 rows  >>>>>  Time Taken: 00:00:11


DROP TABLE #MatchDuplicate

INSERT INTO #FileDuplicate(FileID, RowNum, MatchCount)
SELECT FileID, RowNum, COUNT(*) AS freq
FROM MI.SchemeTransUniqueID WITH (NOLOCK)
WHERE FileID IS NOT NULL
GROUP BY FileID, RowNum
HAVING COUNT(*) > 1;

DELETE u
FROM MI.SchemeTransUniqueID u
INNER JOIN #FileDuplicate m ON u.FileID = m.FileID AND u.RowNum = m.RowNum
WHERE u.MatchID IS NULL;

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Deleted FileID/RowNum duplicates: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Deleted FileID/RowNum duplicates: 0 rows  >>>>>  Time Taken: 00:00:48

DROP TABLE #FileDuplicate


--------------------------------------------------------------
-- [MI].[SchemeTransUniqueID_Indexes_Rebuild]
-- With this new fillfactor setting, it might not be necessary to disable/rebuild these indexes
--------------------------------------------------------------
ALTER INDEX IX_MI_SchemeTransUniqueID_MatchID ON MI.SchemeTransUniqueID REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON);
SET @msg = 'Rebuilt index IX_MI_SchemeTransUniqueID_MatchID'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Rebuilt index IX_MI_SchemeTransUniqueID_MatchID  >>>>>  Time Taken: 00:00:15

ALTER INDEX IX_MI_SchemeTransUniqueID_FileIDRowNum ON MI.SchemeTransUniqueID REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON);
SET @msg = 'Rebuilt index IX_MI_SchemeTransUniqueID_FileIDRowNum'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Rebuilt index IX_MI_SchemeTransUniqueID_FileIDRowNum  >>>>>  Time Taken: 00:04:23

RETURN 0