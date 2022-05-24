

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 27/07/2015
-- Description: Shows transactions for a Fan for a given date range
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0093_DirectDebit_TransactionsByFan_Test] (
			@FanID INT,
			@FromDate DATE,
			@ToDate DATE
			)
									
AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID ('tempdb..#FileIDs') IS NOT NULL DROP TABLE #FileIDs
SELECT	DISTINCT ID as FileID
INTO #FileIDs
FROM SLC_Report.dbo.NobleFiles
WHERE	FileType = 'DDTRN'
	AND InDate BETWEEN @FromDate AND @ToDate  


IF OBJECT_ID ('tempdb..#CIN') IS NOT NULL DROP TABLE #CIN
SELECT	SourceUID,
	ClubID,
	FanID
INTO #CIN
FROM Warehouse.Relational.Customer
WHERE FanID = @FanID

CREATE CLUSTERED INDEX IDX_CIN ON #CIN (SourceUID)

SELECT	c.ClubID,
	c.SourceUID as CIN,
	c.FanID,
	ddt.[Date] as TransactionDate,
	OIN,
	Narrative,
	ddt.ClubID,
	Amount as TransactionAmount,
	MatchStatus,
	RewardStatus,
	CASE
		WHEN t.TypeID = 24 THEN 'Awarded to some else'
		WHEN t.TypeID = 23 THEN 'Awarded'
		ELSE 'Unincentivised'
	END as TranType,
	ddt.FileID,
	ddt.RowNum
FROM Archive_Light.dbo.[CBP_DirectDebit_TransactionHistory] ddt with (nolock)
INNER JOIN #CIN c
	ON ddt.SourceUID = c.SourceUID
	AND ddt.ClubID = c.ClubID
INNER JOIN #FileIDs fid
	ON ddt.FileID = fid.FileID
LEFT OUTER JOIN SLC_Report.dbo.Trans t 
	ON t.VectorMajorID = ddt.FileID 
	AND t.VectorMinorID = ddt.RowNum 
	AND t.VectorID = 40
	AND t.TypeID in (23,24)
	AND t.ItemID IN (64,66)
ORDER BY ddt.[Date]


END