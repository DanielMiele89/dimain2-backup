-- =============================================
-- Author:		JEA
-- Create date: 31/07/2013
-- Description: Retrieves details of new MIDs for Tesco
-- =============================================
CREATE PROCEDURE [MI].[TescoNewMIDs_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @LastDate datetime
	SELECT @LastDate = RefreshDate FROM MI.TescoMIDRefreshDate

	CREATE TABLE #BrandMIDs(BrandMIDID int PRIMARY KEY, MID VARCHAR(50))

	INSERT INTO #BrandMIDs(BrandMIDID, MID)
    SELECT n.BrandMIDID, n.MID
	FROM
	(
		SELECT BM.BrandMIDID, BM.MID 
		FROM staging.combination c
		INNER JOIN relational.brandmid bm on c.brandmidid = bm.brandmidid
		INNER JOIN relational.brand b on bm.BrandID = b.BrandID
		WHERE b.brandgroupid = 4
		AND c.inserted > @LastDate
	) n
	LEFT OUTER JOIN
	(
		SELECT DISTINCT c.MID 
		FROM staging.combination c
		INNER JOIN relational.brandmid bm on c.brandmidid = bm.brandmidid
		INNER JOIN relational.brand b on bm.BrandID = b.BrandID
		WHERE b.brandgroupid = 4
		AND c.inserted <= @LastDate
	) t on n.MID = t.MID
	LEFT OUTER JOIN
	(
		SELECT MID
		FROM MI.TescoMIDCheck
	) c ON n.MID = c.MID
	WHERE t.mid is null
	AND c.MID IS NULL

	CREATE TABLE #MIDInfo(BrandMIDID int primary key
		, MID varchar(50) not null
		, FileID int not null
		, RowNum int
		, Narrative varchar(50)
		, MCC varchar(4)
		, CardholderPresentData varchar(1))

	INSERT INTO #MIDInfo(BrandMIDID, MID, FileID)
	SELECT b.BrandMIDID, b.MID, MAX(c.FileID) AS FileID
	FROM Relational.CardTransaction c WITH (NOLOCK)
	INNER JOIN #BrandMIDs b on c.BrandMIDID = b.BrandMIDID
	GROUP BY b.BrandMIDID, b.MID

	UPDATE #MIDInfo SET RowNum = c.RowNum
	FROM #MIDInfo M
	INNER JOIN (SELECT m.BrandMIDID, m.FileID, MAX(c.RowNum) AS RowNum
				FROM #MIDInfo m
				INNER JOIN Relational.CardTransaction c 
					ON m.BrandMIDID = c.BrandMIDID 
					and m.FileID = c.FileID
				GROUP BY m.BrandMIDID, m.FileID) c on m.BrandMIDID = c.BrandMIDID

	UPDATE #MIDInfo SET Narrative = c.Narrative, MCC = c.MCC, CardholderPresentData = c.CardholderPresentData
	FROM #MIDInfo M
	INNER JOIN (SELECT m.BrandMIDID, c.Narrative, c.MCC, c.CardholderPresentData
				FROM #MIDInfo m
				INNER JOIN Relational.CardTransaction c 
					ON m.BrandMIDID = c.BrandMIDID 
					and m.FileID = c.FileID
					and m.RowNum = c.RowNum) c on m.BrandMIDID = c.BrandMIDID

	SELECT b.BrandID
		, b.BrandName AS Brand 
		, m.MID
		, m.Narrative
		, m.CardholderPresentData
		, m.MCC
		, mcc.MCCDesc
	FROM #MIDInfo m
	INNER JOIN Relational.BrandMID bm on m.BrandMIDID = bm.BrandMIDID
	INNER JOIN Relational.Brand b on bm.BrandID = b.BrandID
	INNER JOIN Relational.MCCList mcc on m.MCC = mcc.MCC

	UPDATE MI.TescoMIDRefreshDate SET RefreshDate = GETDATE()

END
