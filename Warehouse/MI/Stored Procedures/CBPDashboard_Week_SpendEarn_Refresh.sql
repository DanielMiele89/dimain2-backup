-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Spend and Earning figures for CBP Weekly Dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_SpendEarn_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @ThisWeekStart DATE, @ThisWeekEnd DATE, @LastWeekStart DATE, @LastWeekEnd DATE, @YearStart DATE, @LastMonthEnd DATE, @ThisMonthStart DATE

	SET @ThisWeekEnd = DATEADD(DAY, -1, GETDATE())
	SET @ThisWeekStart = DATEADD(DAY, -6, @ThisWeekEnd)
	SET @LastWeekEnd = DATEADD(DAY, -1, @ThisWeekStart)
	SET @LastWeekStart = DATEADD(DAY, -6, @LastWeekend)
	SET @YearStart = DATEFROMPARTS(YEAR(@ThisWeekStart), 1, 1)

	SET @ThisMonthStart = DATEFROMPARTS(YEAR(@ThisWeekStart), MONTH(@ThisWeekStart), 1)
	SET @LastMonthEnd = DATEADD(DAY, -1, @ThisMonthStart)

	DECLARE @SpendThisWeekRBS MONEY, @EarnedThisWeekRBS MONEY, @SpendersThisWeekRBS INT, @TransactionsThisWeekRBS INT, @TransactionsThisWeekRBSContactless INT
		, @SpendLastWeekRBS MONEY, @EarnedLastWeekRBS MONEY, @SpendersLastWeekRBS INT, @TransactionsLastWeekRBS INT, @TransactionsLastWeekRBSContactless INT
		, @SpendYearRBS MONEY, @EarnedYearRBS MONEY, @SpendersYearRBS INT, @TransactionsYearRBS INT, @TransactionsYearRBSContactless INT
		, @SpendThisWeekCoalition MONEY, @EarnedThisWeekCoalition MONEY, @SpendersThisWeekCoalition INT, @TransactionsThisWeekCoalition INT, @TransactionsThisWeekCoalitionContactless INT
		, @SpendLastWeekCoalition MONEY, @EarnedLastWeekCoalition MONEY, @SpendersLastWeekCoalition INT, @TransactionsLastWeekCoalition INT, @TransactionsLastWeekCoalitionContactless INT
		, @SpendYearCoalition MONEY, @EarnedYearCoalition MONEY, @SpendersYearCoalition INT, @TransactionsYearCoalition INT, @TransactionsYearCoalitionContactless INT
		, @CoalitionCustomersMonthToDate INT, @CoalitionCustomersMonthAverage INT, @CoalitionCustomersYear INT

	DECLARE @DatesetStart DATE

	IF @YearStart > @LastWeekStart
	BEGIN
		SELECT @DatesetStart = @LastWeekStart
	END
	ELSE
	BEGIN
		SELECT @DateSetStart = @YearStart
	END

	CREATE TABLE #SpendList(ID INT PRIMARY KEY IDENTITY
		, Spend MONEY NOT NULL
		, Earnings MONEY NOT NULL
		, FanID INT NOT NULL
		, IsCoalition BIT NOT NULL
		, CashbackTypeID TINYINT NOT NULL
		, AddedDate DATE)

	CREATE TABLE #RBSFunded(PartnerID INT PRIMARY KEY, IsCoalition BIT NOT NULL)

	INSERT INTO #RBSFunded(PartnerID, IsCoalition)
	SELECT p.PartnerID, CAST(0 AS BIT)
	FROM Relational.[Partner] p
	INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
	WHERE b.ChargeOnRedeem = 1

	--partnertrans transactions
	INSERT INTO #SpendList(Spend, Earnings, FanID, IsCoalition, CashbackTypeID, AddedDate)
	SELECT TransactionAmount, CashbackEarned, FanID, COALESCE(r.IsCoalition, 1), 0, AddedDate
	FROM Relational.PartnerTrans p
	LEFT OUTER JOIN #RBSFunded r ON p.PartnerID = r.PartnerID
	WHERE AddedDate BETWEEN @DatesetStart AND @ThisWeekEnd

	INSERT INTO #SpendList(Spend, Earnings, FanID, IsCoalition, CashbackTypeID, AddedDate)
	SELECT 0, a.CashbackEarned, a.FanID, COALESCE(r.IsCoalition, 1), a.AdditionalCashbackAwardTypeID, a.AddedDate
	FROM Relational.AdditionalCashbackAward a
	INNER JOIN Relational.PartnerTrans p ON a.MatchID = p.MatchID
	LEFT OUTER JOIN #RBSFunded r ON p.PartnerID = r.PartnerID
	WHERE a.AddedDate BETWEEN @DatesetStart AND @ThisWeekEnd

	INSERT INTO #SpendList(Spend, Earnings, FanID, IsCoalition, CashbackTypeID, AddedDate)
	SELECT a.Amount, a.CashbackEarned, a.FanID, 0 AS IsCoalition, a.AdditionalCashbackAwardTypeID, a.AddedDate
	FROM Relational.AdditionalCashbackAward a
	WHERE a.AddedDate BETWEEN @DatesetStart AND @ThisWeekEnd
	AND MatchID IS NULL

	---***RBS SECTION***---

	--RBS THIS WEEK
	SELECT @SpendThisWeekRBS = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND IsCoalition = 0

	SELECT @EarnedThisWeekRBS = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @SpendersThisWeekRBS = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @TransactionsThisWeekRBS = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND IsCoalition = 0

	SELECT @TransactionsThisWeekRBSContactless = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND IsCoalition = 0 AND CashbackTypeID = 1

	--RBS LAST WEEK
	SELECT @SpendLastWeekRBS = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND IsCoalition = 0

	SELECT @EarnedLastWeekRBS = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @SpendersLastWeekRBS = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @TransactionsLastWeekRBS = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND IsCoalition = 0

	SELECT @TransactionsLastWeekRBSContactless = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND IsCoalition = 0 AND CashbackTypeID = 1

	--RBS YEAR TO DATE
	SELECT @SpendYearRBS = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND IsCoalition = 0

	SELECT @EarnedYearRBS = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @SpendersYearRBS = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @TransactionsYearRBS = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND IsCoalition = 0 --all non-coalition transactions count

	SELECT @TransactionsYearRBSContactless = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND IsCoalition = 0 AND CashbackTypeID = 1 --contactless only

	---***COALITION SECTION***---

	--Coalition THIS WEEK
	SELECT @SpendThisWeekCoalition = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND IsCoalition = 1

	SELECT @EarnedThisWeekCoalition = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @SpendersThisWeekCoalition = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @TransactionsThisWeekCoalition = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0 --do not double-count additional awards coalition transactions

	SELECT @TransactionsThisWeekCoalitionContactless = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 1 --coalition contactless transactions count here

	--Coalition LAST WEEK
	SELECT @SpendLastWeekCoalition = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND IsCoalition = 1

	SELECT @EarnedLastWeekCoalition = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @SpendersLastWeekCoalition = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @TransactionsLastWeekCoalition = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @TransactionsLastWeekCoalitionContactless = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 1

	--Coalition YEAR TO DATE
	SELECT @SpendYearCoalition = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND IsCoalition = 1

	SELECT @EarnedYearCoalition = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @SpendersYearCoalition = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @TransactionsYearCoalition = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0 --all non-coalition transactions count

	SELECT @TransactionsYearCoalitionContactless = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 1 --contactless only

	--COALITION CUSTOMERS MONTH TO DATE
	SELECT @CoalitionCustomersMonthToDate = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate >= @ThisMonthStart
	AND IsCoalition = 1 AND CashbackTypeID = 0

	--COALITION CUSTOMERS MONTHLY AVERAGE SINCE YEAR START
	SELECT @CoalitionCustomersMonthAverage = CAST(AVG(CustomerCount) AS INT)
	FROM
	(
		SELECT COUNT(DISTINCT FanID) AS CustomerCount, MONTH(AddedDate) AS AddedMonth
		FROM #SpendList
		WHERE AddedDate BETWEEN @YearStart AND @LastMonthEnd
		AND IsCoalition = 1 AND CashbackTypeID = 0
		GROUP BY MONTH(AddedDate)
	) M

	SET @CoalitionCustomersMonthAverage = COALESCE(@CoalitionCustomersMonthAverage, @CoalitionCustomersMonthToDate)

	--COALITION CUSTOMERS SINCE YEAR START
	SELECT @CoalitionCustomersYear = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisWeekEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	DELETE FROM MI.CBPDashboard_Week_SpendEarn

	INSERT INTO MI.CBPDashboard_Week_SpendEarn(SpendThisWeekRBS, EarnedThisWeekRBS, SpendersThisWeekRBS, TransactionsThisWeekRBS, SpendLastWeekRBS, EarnedLastWeekRBS, SpendersLastWeekRBS
		, TransactionsLastWeekRBS, SpendYearRBS, EarnedYearRBS, SpendersYearRBS, TransactionsYearRBS, SpendThisWeekCoalition, EarnedThisWeekCoalition, SpendersThisWeekCoalition, TransactionsThisWeekCoalition
		, SpendLastWeekCoalition, EarnedLastWeekCoalition, SpendersLastWeekCoalition, TransactionsLastWeekCoalition, SpendYearCoalition, EarnedYearCoalition, SpendersYearCoalition, TransactionsYearCoalition
		, CoalitionCustomersMonthToDate, CoalitionCustomersMonthAverage, CoalitionCustomersYear
		, TransactionsThisWeekRBSContactless, TransactionsLastWeekRBSContactless, TransactionsYearRBSContactless
		, TransactionsThisWeekCoalitionContactless, TransactionsLastWeekCoalitionContactless, TransactionsYearCoalitionContactless)
	SELECT  @SpendThisWeekRBS SpendThisWeekRBS, @EarnedThisWeekRBS EarnedThisWeekRBS, @SpendersThisWeekRBS SpendersThisWeekRBS, @TransactionsThisWeekRBS TransactionsThisWeekRBS
		, @SpendLastWeekRBS SpendLastWeekRBS, @EarnedLastWeekRBS EarnedLastWeekRBS, @SpendersLastWeekRBS SpendersLastWeekRBS, @TransactionsLastWeekRBS TransactionsLastWeekRBS
		, @SpendYearRBS SpendYearRBS, @EarnedYearRBS EarnedYearRBS, @SpendersYearRBS SpendersYearRBS, @TransactionsYearRBS TransactionsYearRBS
		, @SpendThisWeekCoalition SpendThisWeekCoalition, @EarnedThisWeekCoalition EarnedThisWeekCoalition, @SpendersThisWeekCoalition SpendersThisWeekCoalition
		, @TransactionsThisWeekCoalition TransactionsThisWeekCoalition
		, @SpendLastWeekCoalition SpendLastWeekCoalition, @EarnedLastWeekCoalition EarnedLastWeekCoalition, @SpendersLastWeekCoalition SpendersLastWeekCoalition
		, @TransactionsLastWeekCoalition TransactionsLastWeekCoalition
		, @SpendYearCoalition SpendYearCoalition, @EarnedYearCoalition EarnedYearCoalition, @SpendersYearCoalition SpendersYearCoalition, @TransactionsYearCoalition TransactionsYearCoalition
		, @CoalitionCustomersMonthToDate CoalitionCustomersMonthToDate, @CoalitionCustomersMonthAverage CoalitionCustomersMonthAverage, @CoalitionCustomersYear CoalitionCustomersYear
		, @TransactionsThisWeekRBSContactless, @TransactionsLastWeekRBSContactless, @TransactionsYearRBSContactless
		, @TransactionsThisWeekCoalitionContactless, @TransactionsLastWeekCoalitionContactless, @TransactionsYearCoalitionContactless
	
END