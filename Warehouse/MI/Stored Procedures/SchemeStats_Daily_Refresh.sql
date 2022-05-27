-- =============================================
-- Author:		JEA
-- Create date: 18/03/2014
-- Description:	Populates daily stats for all Reward's schemes
-- (currently CB+ & Quidco)
-- =============================================
CREATE PROCEDURE [MI].[SchemeStats_Daily_Refresh]
WITH EXECUTE AS OWNER
AS
BEGIN
	
	/*
		************OBSOLETE*************
	*/

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.SchemeStats_Daily

	CREATE TABLE #QueryDates(DateID TINYINT PRIMARY KEY IDENTITY
		, DateDesc VARCHAR(50)
		, StartDate DATETIME NOT NULL
		, EndDate DATETIME NOT NULL)

	DECLARE @LatestDate DATETIME, @LatestEnd DATETIME, @LatestWeekStart DATETIME, @LatestMonthStart DATETIME
		, @PrevDayStart DATETIME, @PrevDayEnd DATETIME, @PrevWeekStart DATETIME, @PrevWeekEnd DATETIME, @PrevMonthStart DATETIME, @PrevMonthEnd DATETIME
		, @YearDayStart DATETIME, @YearDayEnd DATETIME, @YearWeekStart DATETIME, @YearMonthStart DATETIME
		, @WeekEndDate DATE

	SELECT @LatestDate = MAX(AddedDate) FROM Relational.PartnerTrans
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
	

	INSERT INTO #QueryDates(DateDesc, StartDate, EndDate)
	VALUES('Today', @LatestDate, @LatestEnd)
		, ('Last Week', @LatestWeekStart, @LatestEnd)
		, ('Last Month', @LatestMonthStart, @LatestEnd)
		, ('Previous Day', @PrevDayStart, @PrevDayEnd)
		, ('Previous Week', @PrevWeekStart, @PrevWeekEnd)
		, ('Previous Month', @PrevMonthStart, @PrevMonthEnd)
		, ('Today -1 Year', @YearDayStart, @YearDayEnd)
		, ('Last Week -1 Year', @YearWeekStart, @YearDayEnd)
		, ('Last Month -1 Year', @YearMonthStart, @YearDayEnd)

	CREATE INDEX IX_TMP_QueryDates ON #QueryDates(StartDate, EndDate, DateID, DateDesc)

	INSERT INTO MI.SchemeStats_Daily(DateID, DateDesc, SchemeName, Spend, Earnings, TransactionCount, CustomerCount)

	SELECT q.DateID
		, q.DateDesc
		, 'CashbackPlus' AS SchemeName
		, ISNULL(SUM(p.TransactionAmount),0) AS Spend
		, ISNULL(SUM(p.CashbackEarned),0) AS Earnings
		, ISNULL(COUNT(1),0) AS TransactionCount
		, ISNULL(COUNT(DISTINCT p.FanID),0) AS CustomerCount
	FROM Relational.PartnerTrans p
	RIGHT OUTER JOIN #QueryDates q ON P.AddedDate BETWEEN q.StartDate AND q.EndDate
	WHERE (p.MatchID IS NULL OR p.EligibleForCashBack = 1)
	AND p.PartnerID != 4433 AND p.PartnerID != 4447
	GROUP BY q.DateID
			, q.DateDesc

	UNION

	SELECT q.DateID
		, q.DateDesc
		,'Quidco' AS SchemeName
		, ISNULL(SUM(match.Amount), 0) AS Spend
		, ISNULL(SUM(match.AffiliateCommissionAmount), 0) AS Earnings
		, ISNULL(COUNT(1), 0) AS TransactionCount
		, ISNULL(COUNT (distinct p.compositeid), 0) AS CustomerCount
	FROM #QueryDates q
	LEFT OUTER JOIN SLC_Report.dbo.Match ON Match.AddedDate BETWEEN q.StartDate AND q.EndDate
	LEFT OUTER JOIN SLC_Report.dbo.Pan p ON Match.PanID = p.ID
	WHERE p.AffiliateID = 12 			
		AND Match.[status] = 1-- Valid transaction status
	GROUP BY q.DateID
		, q.DateDesc

	DROP TABLE #QueryDates

	SELECT @WeekEndDate = MAX(EndDate) FROM MI.SchemeStats_Weekly

	DECLARE @StartDate DATE, @EndDateTime DATETIME

	WHILE @LatestDate > @WeekEndDate
	BEGIN
		SET @WeekEndDate = DATEADD(DAY, 1, @WeekEndDate)
		SET @StartDate = DATEADD(DAY, -6, @WeekEndDate)
		SET @EndDateTime = DATEADD(MINUTE, -1,CAST(DATEADD(DAY, 1, @WeekEndDate) AS DATETIME))

		INSERT INTO MI.SchemeStats_Weekly(StartDate, EndDate, Spend, Earnings, TransactionCount, CustomerCount)

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
				AND p.PartnerID != 4433 AND p.PartnerID != 4447
				AND P.AddedDate BETWEEN @StartDate AND @WeekEndDate


				UNION

				SELECT 'Quidco' AS SchemeName
					, ISNULL(SUM(match.Amount), 0) AS Spend
					, ISNULL(SUM(match.AffiliateCommissionAmount), 0) AS Earnings
					, ISNULL(COUNT(1), 0) AS TransactionCount
					, ISNULL(COUNT (distinct p.compositeid), 0) AS CustomerCount
				FROM SLC_Report.dbo.Match
				INNER JOIN SLC_Report.dbo.Pan p ON Match.PanID = p.ID
				WHERE p.AffiliateID = 12 			
					AND Match.[status] = 1-- Valid transaction status
					AND Match.AddedDate BETWEEN @StartDate AND @EndDateTime
			)t

	END

END
