-- =============================================
-- Author:		JEA
-- Create date: 21/02/2013
-- Description:	Loads staging table for MID Origin Match
-- =============================================
CREATE PROCEDURE [Staging].[MIDOriginInfo_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #MIDOriginInfo(BrandMIDID Int not null
	, BrandID SmallInt not null
	, LastTranDate date not null
	, MaxFileID int
	, RowNum int
	, MID VarChar(50)
	, Narrative VarChar(50)
	, LocationAddress VarChar(50)
	, OriginatorID VarChar(11)
	, MCC VarChar(4)
	)

	INSERT INTO #MIDOriginInfo(BrandMIDID, BrandID, LastTranDate)

	SELECT B.BrandMIDID, B.BrandID, MAX(CT.TranDate) AS LastTranDate
	FROM Relational.BrandMID b with (NOLOCK)
	INNER JOIN Relational.CardTransaction ct with (NOLOCK) on b.BrandMIDID = ct.BrandMIDID
	WHERE ct.TranDate BETWEEN DATEADD(month, -13, getdate()) AND GETDATE()
	AND B.Country = 'GB'
	GROUP BY B.BrandMIDID, B.BrandID

	ALTER TABLE #MIDOriginInfo ADD PRIMARY KEY(BrandMIDID)

	UPDATE #MIDOriginInfo SET MaxFileID = ct.FileID, RowNum = CT.RowNum
	FROM #MIDOriginInfo M
	INNER JOIN Relational.CardTransaction CT with (nolock) on m.BrandMIDID = ct.BrandMIDID and m.LastTranDate = ct.TranDate

	UPDATE #MIDOriginInfo SET MID = B.MID
	FROM Relational.BrandMID B
	INNER JOIN #MIDOriginInfo M ON b.BrandMIDID = M.BrandMIDID

	CREATE NONCLUSTERED INDEX IX_MIDOriginInfoTemp_FileIDRowNum ON #MIDOriginInfo(MaxFileID, RowNum)

	UPDATE #MIDOriginInfo SET Narrative = CT.Narrative, LocationAddress = CT.LocationAddress, MCC = CT.MCC
	FROM Relational.CardTransaction CT WITH (NOLOCK)
	INNER JOIN #MIDOriginInfo M ON CT.FileID = M.MaxFileID AND CT.RowNum = M.RowNum

	UPDATE #MIDOriginInfo SET OriginatorID = NTH.OriginatorID
	FROM Archive.dbo.NobleTransactionHistory NTH WITH (NOLOCK)
	INNER JOIN #MIDOriginInfo M ON NTH.FileID = M.MaxFileID AND NTH.RowNum = M.RowNum

	UPDATE #MIDOriginInfo SET OriginatorID = NTH.OriginatorID
	FROM Archive.dbo.NobleRainbowTransactionPreliminary NTH WITH (NOLOCK)
	INNER JOIN #MIDOriginInfo M ON NTH.FileID = M.MaxFileID AND NTH.RowNum = M.RowNum
	WHERE M.OriginatorID IS NULL

	TRUNCATE TABLE Staging.MIDOriginInfo

	INSERT INTO Staging.MIDOriginInfo(BrandMIDID, BrandID, LastTranDate, MaxFileID, RowNum, MID, Narrative, LocationAddress, OriginatorID, MCC)
	SELECT BrandMIDID, BrandID, LastTranDate, MaxFileID, RowNum, MID, Narrative, LocationAddress, OriginatorID, MCC
	FROM #MIDOriginInfo

	DROP TABLE #MIDOriginInfo
	
	IF EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_Staging_MIDOriginMatch_BrandID')
	BEGIN
		DROP INDEX IX_Staging_MIDOriginMatch_BrandID ON Staging.MIDOriginMatch
	END
	
	TRUNCATE TABLE Staging.MIDOriginMatch
END
