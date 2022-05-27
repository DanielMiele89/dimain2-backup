-- =============================================
-- Author:		JEA
-- Create date: 17/11/2014
-- Description:	Populates daily stats for all Reward's schemes
-- (currently CB+ & Quidco)
-- CJM 20161117 Perf
-- =============================================
CREATE PROCEDURE [MI].[SchemeStats_DailyTranDate_Refresh]
WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE MI.SchemeStats_Daily_TranDate
	TRUNCATE TABLE MI.SchemeStats_Weekly_TranDate

	CREATE TABLE #QueryDates(DateID TINYINT PRIMARY KEY IDENTITY
		, DateDesc VARCHAR(50)
		, StartDate DATETIME NOT NULL
		, EndDate DATETIME NOT NULL
		, SpendExtraCBP MONEY NOT NULL
		, EarnExtraCBP MONEY NOT NULL
		, TranCountExtraCBP INT NOT NULL
		, CustomerCountExtraCBP INT NOT NULL
		, SpendExtraQC MONEY NOT NULL
		, EarnExtraQC MONEY NOT NULL
		, TranCountExtraQC INT NOT NULL
		, CustomerCountExtraQC INT NOT NULL)

	DECLARE @LatestDate DATETIME, @LatestEnd DATETIME, @LatestWeekStart DATETIME, @LatestMonthStart DATETIME
		, @PrevDayStart DATETIME, @PrevDayEnd DATETIME, @PrevWeekStart DATETIME, @PrevWeekEnd DATETIME, @PrevMonthStart DATETIME, @PrevMonthEnd DATETIME
		, @YearDayStart DATETIME, @YearDayEnd DATETIME, @YearWeekStart DATETIME, @YearMonthStart DATETIME
		, @WeekEndDate DATE
		, @SpendExtraCPB MONEY, @EarnExtraCPB MONEY, @TranCountExtraCPB INT, @CustomerCountExtraCPB INT
		, @SpendExtraQC MONEY, @EarnExtraQC MONEY, @TranCountExtraQC INT, @CustomerCountExtraQC INT
		, @MaxWeekID INT, @MaxWeekEnd DATE
		, @QuidcoCheckDate DATE

	--use TRANSACTION DATE
	--start from two days earlier than the latest data received
	--SELECT @LatestDate = DATEADD(DAY, -2, MAX(TransactionDate)) FROM Relational.PartnerTrans
	--JEA 07/05/2015 - New algorithm to account for differential receipt of debit and credit card data
	SELECT @LatestDate = MAX(TransactionDate)
	FROM
	(
		SELECT TransactionDate, TranCount, SUM(TranCount) OVER (ORDER BY Transactiondate ROWS BETWEEN 30 PRECEDING AND CURRENT ROW)/30 AS TranAvg
		FROM
		(
			SELECT TransactionDate, CAST(COUNT(*) AS FLOAT) As TranCount
			FROM Relational.PartnerTrans
			WHERE TransactionDate >= DATEADD(MONTH, -2, GETDATE())
			GROUP BY TransactionDate
		) T
	) t
	WHERE TranCount/TranAvg >= 0.6

	SELECT @QuidcoCheckDate = MAX(Match.TransactionDate)
	FROM SLC_Report.dbo.Match
	INNER JOIN SLC_Report.dbo.Pan p ON Match.PanID = p.ID
	INNER JOIN SLC_Report.dbo.Fan f ON p.CompositeID = f.CompositeID
	INNER JOIN SLC_Report.dbo.Trans t on t.MatchID = match.ID
	WHERE f.ClubID = 12 			
		AND Match.[status] = 1-- Valid transaction status

	IF @LatestDate > @QuidcoCheckDate
	BEGIN
		SET @LatestDate = @QuidcoCheckDate
	END

	SET @LatestEnd = DATEADD(MINUTE, -1,DATEADD(DAY, 1, @LatestDate))
	SET @LatestWeekStart =  DATEADD(day, -6, @LatestDate)
	SET @LatestMonthStart = DATEADD(day, -29, @LatestDate)
	SET @PrevDayStart = DATEADD(DAY, -1, @LatestDate)
	SET @PrevDayEnd = DATEADD(MINUTE, -1, @LatestDate)
	SET @PrevWeekStart = DATEADD(WEEK, -1, @LatestWeekStart)
	SET @PrevWeekEnd = DATEADD(MINUTE, -1, @LatestWeekStart)
	SET @PrevMonthStart = DATEADD(DAY, -30, @LatestMonthStart)
	SET @PrevMonthEnd = DATEADD(MINUTE, -1, @LatestMonthStart)
	SET @YearDayStart = DATEADD(WEEK, -52, @LatestDate)
	SET @YearDayEnd = DATEADD(MINUTE, -1, DATEADD(DAY, 1, @YearDayStart))
	SET @YearWeekStart = DATEADD(DAY, -6, @YearDayStart)
	SET @YearMonthStart = DATEADD(DAY, -30, @YearDayStart)

	SELECT @SpendExtraCPB = ISNULL(SUM(TransactionAmount)/100,0)
		, @EarnExtraCPB = ISNULL(SUM(CashbackEarned)/100,0)
		, @TranCountExtraCPB = ISNULL(COUNT(1)/100,0)
		, @CustomerCountExtraCPB = ISNULL(COUNT(DISTINCT FanID)/100,0)
	FROM Relational.PartnerTrans
	WHERE TransactionDate = @LatestDate

	SELECT @SpendExtraQC = ISNULL(SUM(match.Amount)/100,0)
		, @EarnExtraQC = ISNULL(SUM(t.CommissionEarned)/100,0)
		, @TranCountExtraQC = ISNULL(COUNT(1)/100,0)
		, @CustomerCountExtraQC = ISNULL(COUNT(DISTINCT p.compositeid)/100,0)
	FROM SLC_Report.dbo.Match
	INNER JOIN SLC_Report.dbo.Pan p ON Match.PanID = p.ID
	INNER JOIN SLC_Report.dbo.Fan f ON p.CompositeID = f.CompositeID
	INNER JOIN SLC_Report.dbo.Trans t on t.MatchID = match.ID
	WHERE f.ClubID = 12 			
		AND Match.[status] = 1-- Valid transaction status
		AND Match.TransactionDate >= @LatestDate
		AND Match.TransactionDate <= @LatestEnd

	INSERT INTO #QueryDates(DateDesc, StartDate, EndDate, SpendExtraCBP, EarnExtraCBP, TranCountExtraCBP, CustomerCountExtraCBP
							, SpendExtraQC, EarnExtraQC, TranCountExtraQC, CustomerCountExtraQC)
	VALUES('Today', @LatestDate, @LatestEnd, @SpendExtraCPB, @EarnExtraCPB, @TranCountExtraCPB, @CustomerCountExtraCPB
					, @SpendExtraQC, @EarnExtraQC, @TranCountExtraQC, @CustomerCountExtraQC)
		, ('Last Week', @LatestWeekStart, @LatestEnd, @SpendExtraCPB, @EarnExtraCPB, @TranCountExtraCPB, @CustomerCountExtraCPB
					, @SpendExtraQC, @EarnExtraQC, @TranCountExtraQC, @CustomerCountExtraQC)
		, ('Last Month', @LatestMonthStart, @LatestEnd, @SpendExtraCPB, @EarnExtraCPB, @TranCountExtraCPB, @CustomerCountExtraCPB
					, @SpendExtraQC, @EarnExtraQC, @TranCountExtraQC, @CustomerCountExtraQC)
		, ('Previous Day', @PrevDayStart, @PrevDayEnd,0,0,0,0,0,0,0,0)
		, ('Previous Week', @PrevWeekStart, @PrevWeekEnd,0,0,0,0,0,0,0,0)
		, ('Previous Month', @PrevMonthStart, @PrevMonthEnd,0,0,0,0,0,0,0,0)
		, ('Today -1 Year', @YearDayStart, @YearDayEnd,0,0,0,0,0,0,0,0)
		, ('Last Week -1 Year', @YearWeekStart, @YearDayEnd,0,0,0,0,0,0,0,0)
		, ('Last Month -1 Year', @YearMonthStart, @YearDayEnd,0,0,0,0,0,0,0,0)

	CREATE INDEX IX_TMP_QueryDates ON #QueryDates(StartDate, EndDate, DateID, DateDesc)

	INSERT INTO MI.SchemeStats_Daily_TranDate(DateID, DateDesc, SchemeName, Spend, Earnings, TransactionCount, CustomerCount)

	SELECT q.DateID
		, q.DateDesc
		, 'CashbackPlus' AS SchemeName
		, ISNULL(SUM(p.TransactionAmount) + Q.SpendExtraCBP,0) AS Spend
		, ISNULL(SUM(p.CashbackEarned) + Q.EarnExtraCBP,0) AS Earnings
		, ISNULL(COUNT(1) + Q.TranCountExtraCBP,0) AS TransactionCount
		, ISNULL(COUNT(DISTINCT p.FanID) + Q.CustomerCountExtraCBP,0) AS CustomerCount
	FROM Relational.PartnerTrans p
	RIGHT OUTER JOIN #QueryDates q ON P.TransactionDate BETWEEN q.StartDate AND q.EndDate
	WHERE (p.MatchID IS NULL OR p.EligibleForCashBack = 1)
	AND p.PartnerID != 4433 AND p.PartnerID != 4447 AND p.PartnerID != 3960
	GROUP BY q.DateID
			, q.DateDesc
			, q.SpendExtraCBP
			, q.EarnExtraCBP
			, q.TranCountExtraCBP
			, q.CustomerCountExtraCBP

	UNION

	SELECT q.DateID
		, q.DateDesc
		,'Quidco' AS SchemeName
		, ISNULL(SUM(match.Amount) + @SpendExtraQC, 0) AS Spend
		, ISNULL(SUM(t.CommissionEarned) + @EarnExtraQC, 0) AS Earnings
		, ISNULL(COUNT(1) + @TranCountExtraQC, 0) AS TransactionCount
		, ISNULL(COUNT (DISTINCT p.compositeid) + @CustomerCountExtraQC, 0) AS CustomerCount
	FROM #QueryDates q
	LEFT OUTER JOIN SLC_Report.dbo.Match ON Match.TransactionDate BETWEEN q.StartDate AND q.EndDate
	LEFT OUTER JOIN SLC_Report.dbo.Pan p ON Match.PanID = p.ID
	INNER JOIN SLC_Report.dbo.Fan f ON p.CompositeID = f.CompositeID
	INNER JOIN SLC_Report.dbo.Trans t on t.MatchID = match.ID
	WHERE f.ClubID = 12 			
		AND Match.[status] = 1-- Valid transaction status
	GROUP BY q.DateID
		, q.DateDesc
		, q.SpendExtraQC
		, q.EarnExtraQC
		, q.TranCountExtraQC
		, q.CustomerCountExtraQC

	DROP TABLE #QueryDates

	-------------------------------------------------------
	-- before the date loop
	IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match; CREATE TABLE #Match (Amount SMALLMONEY, PanID INT, ID INT)
	-------------------------------------------------------

	SELECT @WeekEndDate = '2013-08-14'

	DECLARE @StartDate DATE, @EndDateTime DATETIME

	WHILE @LatestDate > @WeekEndDate
	BEGIN
		SET @WeekEndDate = DATEADD(DAY, 1, @WeekEndDate)
		SET @StartDate = DATEADD(DAY, -6, @WeekEndDate)
		SET @EndDateTime = DATEADD(MINUTE, -1,CAST(DATEADD(DAY, 1, @WeekEndDate) AS DATETIME))

		-- within the date loop
		TRUNCATE TABLE #Match
		INSERT INTO #Match (Amount, PanID, ID)
		SELECT match.Amount, Match.PanID, match.ID
		FROM SLC_Report.dbo.Match
		WHERE Match.[status] = 1-- Valid transaction status
			AND Match.TransactionDate BETWEEN @StartDate AND @EndDateTime

		INSERT INTO MI.SchemeStats_Weekly_TranDate(StartDate, EndDate, Spend, Earnings, TransactionCount, CustomerCount)

		SELECT @StartDate, @WeekEndDate, SUM(Spend), SUM(Earnings), SUM(TransactionCount), SUM(CustomerCount)
		FROM
			(
				SELECT 'CashbackPlus' AS SchemeName
					, ISNULL(SUM(p.TransactionAmount),0) AS Spend
					, ISNULL(SUM(p.CashbackEarned),0) AS Earnings
					, ISNULL(COUNT(1),0) AS TransactionCount
					, ISNULL(COUNT(DISTINCT p.FanID),0) AS CustomerCount
				FROM Relational.PartnerTrans p
				WHERE p.EligibleForCashBack = 1
				AND p.PartnerID != 4433 AND p.PartnerID != 4447 AND p.PartnerID != 3960
				AND P.TransactionDate BETWEEN @StartDate AND @WeekEndDate

				UNION ALL

				-- CJM 20161117 two loop joins work well with the tested data
				SELECT 'Quidco' AS SchemeName
					, ISNULL(SUM(match.Amount), 0) AS Spend
					, ISNULL(SUM(t.CommissionEarned), 0) AS Earnings
					, ISNULL(COUNT(1), 0) AS TransactionCount
					, ISNULL(COUNT (DISTINCT p.compositeid), 0) AS CustomerCount
				FROM #Match Match
				INNER loop JOIN SLC_Report.dbo.Pan p ON Match.PanID = p.ID
				INNER loop JOIN SLC_Report.dbo.Fan f ON p.CompositeID = f.CompositeID
				INNER JOIN SLC_Report.dbo.Trans t on t.MatchID = match.ID
				WHERE f.ClubID = 12 			
			)t

	END

	SELECT @MaxWeekID = MAX(ID) FROM MI.SchemeStats_Weekly_TranDate

	SELECT @MaxWeekEnd = EndDate FROM MI.SchemeStats_Weekly_TranDate WHERE ID = @MaxWeekID

	IF @MaxWeekEnd >= @LatestDate
	BEGIN

		UPDATE MI.SchemeStats_Weekly_TranDate
		SET Spend = Spend + @SpendExtraCPB + @SpendExtraQC
			, Earnings = Earnings + @EarnExtraCPB + @EarnExtraQC
			, TransactionCount = TransactionCount + @TranCountExtraCPB + @TranCountExtraQC
			, CustomerCount = CustomerCount + @CustomerCountExtraCPB + @CustomerCountExtraQC
		WHERE ID = @MaxWeekID

	END

END