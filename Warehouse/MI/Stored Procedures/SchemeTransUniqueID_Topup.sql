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

Changed for migration CJM 14/10/2021
*/
CREATE procedure [MI].[SchemeTransUniqueID_Topup]

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
UPDATE s 
	SET MatchID = CASE
		WHEN a.MatchID IS NOT NULL AND s.MatchID IS NULL THEN a.MatchID
		WHEN a.MatchID IS NULL AND s.MatchID IS NOT NULL THEN NULL
		ELSE s.MatchID END
FROM MI.SchemeTransUniqueID s
INNER JOIN Relational.AdditionalCashbackAward a 
	ON s.FileID = a.FileID 
	AND s.RowNum = a.RowNum
	AND ((a.MatchID IS NOT NULL AND s.MatchID IS NULL) OR (a.MatchID IS NULL AND s.MatchID IS NOT NULL))
--WHERE a.MatchID IS NOT NULL AND s.MatchID IS NULL;

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished MatchID update: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Finished first MatchID update: 0 rows  >>>>>  Time Taken: 00:03:48


--------------------------------------------------------------
-- [MI].[SchemeTransUniqueID_PartnerTrans_Fetch] 
--------------------------------------------------------------
INSERT INTO Staging.SchemeTransUniqueID WITH (TABLOCK)
	(MatchID, FileID, RowNum)
SELECT pt.MatchID, x.FileID, x.RowNum
FROM (
	SELECT DISTINCT MatchID
	FROM Relational.PartnerTrans pt
	EXCEPT
	SELECT MatchID FROM MI.SchemeTransUniqueID
) pt 
OUTER APPLY (
	SELECT TOP(1) MatchID, FileID, RowNum
	FROM Relational.AdditionalCashbackAward a 
	WHERE pt.MatchID = a.MatchID
) x
-- (604545 rows affected) / 00:07:04

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Collected PartnerTrans data: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Collected PartnerTrans data: 432554 rows  >>>>>  Time Taken: 00:08:04


--------------------------------------------------------------
-- [MI].[SchemeTransUniqueID_AdditionalCashback_Fetch]
--------------------------------------------------------------
INSERT INTO Staging.SchemeTransUniqueID WITH (TABLOCK) 
	(FileID, RowNum)
SELECT DISTINCT a.FileID, a.RowNum
FROM Relational.AdditionalCashbackAward a 
WHERE NOT EXISTS (
	SELECT 1 FROM MI.SchemeTransUniqueID s  
	WHERE a.FileID = s.FileID AND a.RowNum = s.RowNum
);

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Collected AdditionalCashbackAward data: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Collected AdditionalCashbackAward data: 3499908  >>>>>  Time Taken: 00:10:15


--------------------------------------------------------------
-- [MI].[SchemeTransUniqueID_Indexes_Disable]
--------------------------------------------------------------
--ALTER INDEX IX_MI_SchemeTransUniqueID_MatchID ON MI.SchemeTransUniqueID DISABLE;
--ALTER INDEX IX_MI_SchemeTransUniqueID_FileIDRowNum ON MI.SchemeTransUniqueID DISABLE;


--------------------------------------------------------------
-- [Staging].[SchemeTransUniqueID_Fetch]
--------------------------------------------------------------
INSERT INTO [MI].[SchemeTransUniqueID]  WITH (TABLOCK) 
	(MatchID, FileID, RowNum)
SELECT MatchID, FileID, RowNum
FROM Staging.SchemeTransUniqueID;

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Target table topped up: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Target table topped up: 3932462 rows  >>>>>  Time Taken: 00:01:20


--------------------------------------------------------------
-- MI.SchemeTransUniqueID_RemoveDuplicates
--------------------------------------------------------------
CREATE TABLE #MatchDuplicate (MatchID INT PRIMARY KEY, MatchCount INT NOT NULL)
CREATE TABLE #FileDuplicate (FileID INT NOT NULL, RowNum INT NOT NULL, MatchCount INT NOT NULL)
ALTER TABLE #FileDuplicate ADD PRIMARY KEY (FileID, RowNum)

INSERT INTO #MatchDuplicate 
	(MatchID, MatchCount)
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
-- Deleted MATCH duplicates: 0 rows  >>>>>  Time Taken: 00:00:39


INSERT INTO #FileDuplicate (FileID, RowNum, MatchCount)
SELECT FileID, RowNum, COUNT(*) AS freq
FROM MI.SchemeTransUniqueID WITH (NOLOCK)
WHERE FileID IS NOT NULL
GROUP BY FileID, RowNum
HAVING COUNT(*) > 1;
SET @RowsAffected = @@ROWCOUNT

--CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #FileDuplicate (FileID, RowNum)

IF @RowsAffected > 0 BEGIN
	DELETE u
	FROM MI.SchemeTransUniqueID u
	INNER JOIN #FileDuplicate m 
		ON u.FileID = m.FileID AND u.RowNum = m.RowNum
	WHERE u.MatchID IS NULL;
END

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Deleted FileID/RowNum duplicates: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Deleted FileID/RowNum duplicates: 0 rows  >>>>>  Time Taken: 00:08:20


UPDATE STATISTICS MI.SchemeTransUniqueID

--------------------------------------------------------------
-- [MI].[SchemeTransUniqueID_Indexes_Rebuild]
-- With this new fillfactor setting, it might not be necessary to disable/rebuild these indexes
--------------------------------------------------------------
--ALTER INDEX IX_MI_SchemeTransUniqueID_MatchID ON MI.SchemeTransUniqueID REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON);
--SET @msg = 'Rebuilt index IX_MI_SchemeTransUniqueID_MatchID'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Rebuilt index IX_MI_SchemeTransUniqueID_MatchID  >>>>>  Time Taken: 00:00:15

--ALTER INDEX IX_MI_SchemeTransUniqueID_FileIDRowNum ON MI.SchemeTransUniqueID REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON);
--SET @msg = 'Rebuilt index IX_MI_SchemeTransUniqueID_FileIDRowNum'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- Rebuilt index IX_MI_SchemeTransUniqueID_FileIDRowNum  >>>>>  Time Taken: 00:04:23

RETURN 0