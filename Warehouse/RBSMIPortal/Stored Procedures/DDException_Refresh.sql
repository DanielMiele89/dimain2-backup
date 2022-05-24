-- =============================================
-- Author:		JEA
-- Create date: 02/03/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE RBSMIPortal.DDException_Refresh
WITH EXECUTE AS OWNER	
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE MI.RBSMIPortal_DDException

    DECLARE @StartDate DATE, @EndDate date

	SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @EndDate = DATEADD(DAY, -1, @StartDate)
	SET @StartDate = DATEADD(MONTH, -1, @StartDate)

	CREATE TABLE #HighTrans(FanID INT PRIMARY KEY, ClubID INT NOT NULL, SourceUID VARCHAR(50) NOT NULL, TranCount INT NOT NULL)

	INSERT INTO #HighTrans(FanID
		, ClubID
		, SourceUID
		, TranCount)
	SELECT	c.FanID,
		c.ClubID,
		c.SourceUID,
		COUNT(1) as TranCount
	FROM Warehouse.relational.AdditionalCashbackAward aa
	INNER JOIN Warehouse.Relational.Customer c
		ON aa.FanID = c.FanID
	WHERE	aa.DirectDebitOriginatorID IS NOT NULL
		AND TranDate BETWEEN @StartDate AND @EndDate
	GROUP BY c.FanID, ClubID, SourceUID
	HAVING COUNT(1) > 25
	ORDER BY TranCount DESC

	INSERT INTO MI.RBSMIPortal_DDException(
		ClubID
		, CIN
		, FanID
		, TransactionDate
		, SMonth
		, OIN
		, Narrative
		, TransactionAmount
	)
	SELECT	c.ClubID
		, c.SourceUID as CIN
		, c.FanID
		, ddt.[Date] as TransactionDate
		, Staging.fnGetStartOfMonth(ddt.[Date]) as SMonth
		, OIN
		, Narrative
		, Amount as TransactionAmount
	FROM Archive_Light.dbo.[CBP_DirectDebit_TransactionHistory] ddt with (nolock)
	INNER JOIN #HighTrans c ON ddt.FanID = c.FanID
	LEFT OUTER JOIN SLC_Report.dbo.Trans t 
		ON t.VectorMajorID = ddt.FileID 
		AND t.VectorMinorID = ddt.RowNum 
		AND t.VectorID = 40
		AND t.TypeID = 23
		AND t.ItemID = 64
	WHERE	ddt.[Date] BETWEEN @StartDate AND @EndDate
	ORDER BY ddt.[Date]

END