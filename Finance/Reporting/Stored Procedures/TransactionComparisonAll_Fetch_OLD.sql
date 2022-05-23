CREATE PROCEDURE [Reporting].[TransactionComparisonAll_Fetch_OLD]
AS
BEGIN

	IF OBJECT_ID('tempdb..#EarningsFinance') IS NOT NULL 
		DROP TABLE #EarningsFinance
	select 
		DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0) MonthDate
		, sum(earnings) Earnings
		, FanID
		, TransactionTypeID
	INTO #EarningsFinance
	from Finance.dbo.Transactions
	WHERE TranDate >= '2021-01-01'
	GROUP BY 
		DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0)
		, FanID
		, TransactionTypeID

	IF OBJECT_ID('tempdb..#EarningsProd') IS NOT NULL 
		DROP TABLE #EarningsProd
	SELECT
		DATEADD(MONTH, DATEDIFF(MONTH, 0, Date), 0) MonthDate
		, SUM(Clubcash) AS Earnings
		, FanID
		, t.TypeID
	INTO #EarningsProd
	FROM SLC_Repl..Trans t
	WHERE t.Date >= '2021-01-01'
	GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, Date), 0)
		, FanID
		, t.TypeID

	SELECT
		y.Earnings AS Finance
		, z.Earnings AS Prod
		, FinanceVSProd = y.Earnings - z.Earnings
		, y.MOnthDate
		, z.MonthDate
	FROM (
		SELECT SUM(Earnings), MonthDate, TransactionTypeID
		FROM #EarningsFinance
		GROUP BY MonthDate, TransactionTypeID
	) y(Earnings, MOnthDate, TypeID)
	FULL OUTER JOIN (
		SELECT SUM(Earnings), MonthDate, TypeiD
		FROM #EarningsProd
		GROUP BY MonthDate, TypeID
	) z(Earnings, MonthDate, TypeID)
		ON y.MonthDate = z.MonthDate
		AND y.TypeID = z.TypeID
	ORDER BY y.MonthDate

END