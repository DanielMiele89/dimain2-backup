-- =============================================
-- Author:		Suraj Chahal
-- Create date: 02/07/2014
-- Description:	Returns transactions displaced from a reporting month
--				by differenced between transaction date and added date
-- Edited by Ed Allison 22/07/2014 to include additional cashback awards
-- =============================================
CREATE PROCEDURE [MI].[TranDate_AddedDate_Differential_Fetch]

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @StartDate DATE,
			@EndDate DATE,
			@BaseDate DATE

	SET @BaseDate = DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
	SET @StartDate = DATEADD(MONTH,-1,@BaseDate)
	SET @EndDate = DATEADD(DD,-1,@BaseDate)

	CREATE TABLE #Differential(ID INT PRIMARY KEY IDENTITY
		, ShiftType TINYINT NOT NULL
		, MatchID INT NULL
		, FileID INT NULL
		, RowNum INT NULL
		, Spend MONEY NOT NULL
		, Earnings MONEY NOT NULL)

	INSERT INTO #Differential(ShiftType, MatchID, FileID, RowNum, Spend, Earnings)
	SELECT 1
		, pt.MatchID
		, a.FileID
		, a.RowNum
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned + ISNULL(a.CashbackEarned, 0) AS Earnings
	FROM Relational.PartnerTrans pt
	LEFT OUTER JOIN Relational.AdditionalCashbackAward a ON pt.MatchID = a.MatchID
	WHERE pt.AddedDate BETWEEN @StartDate AND @EndDate
			AND pt.TransactionDate < @StartDate

	INSERT INTO #Differential(ShiftType, MatchID, FileID, RowNum, Spend, Earnings)
	SELECT 1
		, null
		, a.FileID
		, a.RowNum
		, a.Amount AS Spend
		, a.CashbackEarned AS Earnings
	FROM Relational.AdditionalCashbackAward a
	WHERE a.AddedDate BETWEEN @StartDate AND @EndDate
			AND a.TranDate < @StartDate
			AND a.MatchID IS NULL

	INSERT INTO #Differential(ShiftType, MatchID, FileID, RowNum, Spend, Earnings)
	SELECT 2
		, pt.MatchID
		, a.FileID
		, a.RowNum
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned + ISNULL(a.CashbackEarned, 0) AS Earnings
	FROM Relational.PartnerTrans pt
	LEFT OUTER JOIN Relational.AdditionalCashbackAward a ON pt.MatchID = a.MatchID
	WHERE pt.TransactionDate BETWEEN @StartDate AND @EndDate
			AND pt.AddedDate > @EndDate

	INSERT INTO #Differential(ShiftType, MatchID, FileID, RowNum, Spend, Earnings)
	SELECT 2
		, null
		, a.FileID
		, a.RowNum
		, a.Amount AS Spend
		, a.CashbackEarned AS Earnings
	FROM Relational.AdditionalCashbackAward a
	WHERE a.TranDate BETWEEN @StartDate AND @EndDate
			AND a.AddedDate > @EndDate
			AND a.MatchID IS NULL

	SELECT	ShiftType,
			@StartDate as RunMonth, 
			COUNT(1) as Transactions,
			SUM(Spend) as Spend,
			SUM(Earnings) as Earnings
	FROM #Differential
	GROUP BY ShiftType

	DROP TABLE #Differential

END