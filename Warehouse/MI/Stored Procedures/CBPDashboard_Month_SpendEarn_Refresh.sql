-- =============================================
-- Author:		JEA
-- Create date: 15/04/2014
-- Description:	Spend and Earning figures for CBP Monthly Dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_SpendEarn_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @ThisMonthStart DATE, @ThisMonthEnd DATE,@YearStart DATE

	SET @ThisMonthStart = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @ThisMonthEnd = DATEADD(DAY, -1, @ThisMonthStart)
	SET @ThisMonthStart = DATEADD(MONTH, -1, @ThisMonthStart)
	SET @YearStart = DATEFROMPARTS(YEAR(@ThisMonthStart), 1, 1)

	DECLARE @SpendThisMonthRBS MONEY, @EarnedThisMonthRBS MONEY, @SpendersThisMonthRBS INT, @TransactionsThisMonthRBS INT
		, @SpendYearRBS MONEY, @EarnedYearRBS MONEY, @SpendersYearRBS INT, @TransactionsYearRBS INT
		, @SpendThisMonthCoalition MONEY, @EarnedThisMonthCoalition MONEY, @SpendersThisMonthCoalition INT, @TransactionsThisMonthCoalition INT
		, @SpendYearCoalition MONEY, @EarnedYearCoalition MONEY, @SpendersYearCoalition INT, @TransactionsYearCoalition INT
		, @CoalitionCustomersMonthAverage INT, @CoalitionCustomersYear INT

	DECLARE @DatesetStart DATE

	IF @YearStart > @ThisMonthStart
	BEGIN
		SELECT @DatesetStart = @ThisMonthStart
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
	WHERE AddedDate BETWEEN @DatesetStart AND @ThisMonthEnd

	INSERT INTO #SpendList(Spend, Earnings, FanID, IsCoalition, CashbackTypeID, AddedDate)
	SELECT 0, a.CashbackEarned, a.FanID, COALESCE(r.IsCoalition, 1), a.AdditionalCashbackAwardTypeID, a.AddedDate
	FROM Relational.AdditionalCashbackAward a
	INNER JOIN Relational.PartnerTrans p ON a.MatchID = p.MatchID
	LEFT OUTER JOIN #RBSFunded r ON p.PartnerID = r.PartnerID
	WHERE a.AddedDate BETWEEN @DatesetStart AND @ThisMonthEnd

	INSERT INTO #SpendList(Spend, Earnings, FanID, IsCoalition, CashbackTypeID, AddedDate)
	SELECT a.Amount, a.CashbackEarned, a.FanID, 0 AS IsCoalition, a.AdditionalCashbackAwardTypeID, a.AddedDate
	FROM Relational.AdditionalCashbackAward a
	WHERE a.AddedDate BETWEEN @DatesetStart AND @ThisMonthEnd
	AND MatchID IS NULL

	---***RBS SECTION***---

	--RBS THIS MONTH
	SELECT @SpendThisMonthRBS = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd
	AND IsCoalition = 0

	SELECT @EarnedThisMonthRBS = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @SpendersThisMonthRBS = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @TransactionsThisMonthRBS = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd
	AND IsCoalition = 0

	--RBS YEAR TO DATE
	SELECT @SpendYearRBS = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
	AND IsCoalition = 0

	SELECT @EarnedYearRBS = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @SpendersYearRBS = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
	AND (IsCoalition = 0 OR CashbackTypeID > 0)

	SELECT @TransactionsYearRBS = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
	AND IsCoalition = 0 --all non-coalition transactions count

	---***COALITION SECTION***---

	--COALITION THIS MONTH
	SELECT @SpendThisMonthCoalition = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd
	AND IsCoalition = 1

	SELECT @EarnedThisMonthCoalition = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @SpendersThisMonthCoalition = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @TransactionsThisMonthCoalition = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0 --do not double-count additional awards coalition transactions

	--COALITION YEAR TO DATE
	SELECT @SpendYearCoalition = SUM(Spend)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
	AND IsCoalition = 1

	SELECT @EarnedYearCoalition = SUM(Earnings)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @SpendersYearCoalition = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	SELECT @TransactionsYearCoalition = COUNT(1)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0 --all non-coalition transactions count

	--COALITION CUSTOMERS MONTHLY AVERAGE SINCE YEAR START
	SELECT @CoalitionCustomersMonthAverage = CAST(AVG(CustomerCount) AS INT)
	FROM
	(
		SELECT COUNT(DISTINCT FanID) AS CustomerCount, MONTH(AddedDate) AS AddedMonth
		FROM #SpendList
		WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
		AND IsCoalition = 1 AND CashbackTypeID = 0
		GROUP BY MONTH(AddedDate)
	) M

	--COALITION CUSTOMERS SINCE YEAR START
	SELECT @CoalitionCustomersYear = COUNT(DISTINCT FanID)
	FROM #SpendList
	WHERE AddedDate BETWEEN @YearStart AND @ThisMonthEnd
	AND IsCoalition = 1 AND CashbackTypeID = 0

	DELETE FROM MI.CBPDashboard_Month_SpendEarn

	INSERT INTO MI.CBPDashboard_Month_SpendEarn(SpendThisMonthRBS, EarnedThisMonthRBS, SpendersThisMonthRBS, TransactionsThisMonthRBS
		, SpendYearRBS, EarnedYearRBS, SpendersYearRBS, TransactionsYearRBS
		, SpendThisMonthCoalition, EarnedThisMonthCoalition, SpendersThisMonthCoalition, TransactionsThisMonthCoalition
		, SpendYearCoalition, EarnedYearCoalition, SpendersYearCoalition, TransactionsYearCoalition
		, CoalitionCustomersMonthAverage, CoalitionCustomersYear)
	SELECT  @SpendThisMonthRBS SpendThisMonthRBS, @EarnedThisMonthRBS EarnedThisMonthRBS, @SpendersThisMonthRBS SpendersThisMonthRBS, @TransactionsThisMonthRBS TransactionsThisMonthRBS
		, @SpendYearRBS SpendYearRBS, @EarnedYearRBS EarnedYearRBS, @SpendersYearRBS SpendersYearRBS, @TransactionsYearRBS TransactionsYearRBS
		, @SpendThisMonthCoalition SpendThisMonthCoalition, @EarnedThisMonthCoalition EarnedThisMonthCoalition, @SpendersThisMonthCoalition SpendersThisMonthCoalition
		, @TransactionsThisMonthCoalition TransactionsThisMonthCoalition
		, @SpendYearCoalition SpendYearCoalition, @EarnedYearCoalition EarnedYearCoalition, @SpendersYearCoalition SpendersYearCoalition, @TransactionsYearCoalition TransactionsYearCoalition
		, @CoalitionCustomersMonthAverage CoalitionCustomersMonthAverage, @CoalitionCustomersYear CoalitionCustomersYear
	
END