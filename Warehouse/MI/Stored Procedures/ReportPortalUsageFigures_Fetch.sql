-- =============================================
-- Author:		JEA
-- Create date: 06/05/2015
-- Description:	Summarises report portal usage data
-- =============================================
CREATE PROCEDURE [MI].[ReportPortalUsageFigures_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

   DECLARE @MonthStart DATE, @MonthEnd DATE, @CurrentMonthStart DATE, @CurrentYearStart DATE, @YearStart DATE

	SET @CurrentMonthStart = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @CurrentYearStart = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
	SET @MonthStart = DATEADD(MONTH, -1, @CurrentMonthStart)
	SET @MonthEnd = DATEADD(DAY, -1, @CurrentMonthStart)
	SET @YearStart = DATEADD(YEAR, -1, @CurrentMonthStart)

	SELECT Report
		, SUM(UsageCurrentMonth) AS UsageCurrentMonth
		, SUM(UsageCurrentYear) AS UsageCurrentYear
		, SUM(UsageLastMonth) AS UsageLastMonth
		, SUM(UsageLastYear) AS UsageLastYear
		, COUNT(1) AS UsageEver
		, @CurrentMonthStart AS CurrentMonthStart
		, @CurrentYearStart AS CurrentYearStart
		, @MonthStart AS MonthStart
		, @MonthEnd AS MonthEnd
		, @YearStart AS YearStart
	FROM
	(
		SELECT R.Report
			, CAST(CASE WHEN r.RunDate >= @CurrentMonthStart THEN 1 ELSE 0 END AS INT) AS UsageCurrentMonth
			, CAST(CASE WHEN r.RunDate >= @CurrentYearStart THEN 1 ELSE 0 END AS INT) AS UsageCurrentYear
			, CAST(CASE WHEN r.RunDate BETWEEN @MonthStart AND @MonthEnd THEN 1 ELSE 0 END AS INT) AS UsageLastMonth
			, CAST(CASE WHEN r.RunDate BETWEEN @YearStart AND @MonthEnd THEN 1 ELSE 0 END AS INT) AS UsageLastYear
		FROM MI.ReportPortalUseAnalysis R
		LEFT OUTER JOIN MI.ReportPortalRewardUsers U ON R.UserName = U.Username
		WHERE U.Username IS NULL AND R.UserName NOT LIKE '%reward%'
		AND r.RunDate >= '2015-07-19'
	) R
	GROUP BY Report
	ORDER BY UsageEver DESC

END