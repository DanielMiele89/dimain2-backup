-- =============================================
-- Author:		JEA
-- Create date: 10/05/2016
-- Description:	Removes duplicate SchemeTransUniqueID entries
-- =============================================
CREATE PROCEDURE [MI].[SchemeTransUniqueID_RemoveDuplicates] 

AS
BEGIN

	SET NOCOUNT ON;

    CREATE TABLE #MatchDuplicate(MatchID INT PRIMARY KEY, MatchCount INT NOT NULL)
	CREATE TABLE #FileDuplicate(FileID INT NOT NULL, RowNum INT NOT NULL, MatchCount INT NOT NULL)
	ALTER TABLE #FileDuplicate ADD PRIMARY KEY(FileID, RowNum)

	INSERT INTO #MatchDuplicate(MatchID, MatchCount)
	SELECT MatchID, COUNT(*) AS freq
	FROM MI.SchemeTransUniqueID WITH (NOLOCK)
	WHERE MatchID IS NOT NULL
	GROUP BY MatchID
	HAVING COUNT(*) > 1

	DELETE u
	FROM MI.SchemeTransUniqueID u
	INNER JOIN #MatchDuplicate m ON u.MatchID = m.MatchID
	WHERE u.FileID IS NULL

	DROP TABLE #MatchDuplicate

	INSERT INTO #FileDuplicate(FileID, RowNum, MatchCount)
	SELECT FileID, RowNum, COUNT(*) AS freq
	FROM MI.SchemeTransUniqueID WITH (NOLOCK)
	WHERE FileID IS NOT NULL
	GROUP BY FileID, RowNum
	HAVING COUNT(*) > 1

	DELETE u
	FROM MI.SchemeTransUniqueID u
	INNER JOIN #FileDuplicate m ON u.FileID = m.FileID AND u.RowNum = m.RowNum
	WHERE u.MatchID IS NULL

	DROP TABLE #FileDuplicate

END