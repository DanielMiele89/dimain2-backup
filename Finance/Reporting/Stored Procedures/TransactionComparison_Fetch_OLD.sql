CREATE PROCEDURE Reporting.[TransactionComparison_Fetch_OLD]
AS
BEGIN

	IF OBJECT_ID('tempdb..#EarningsTableau') IS NOT NULL 
		DROP TABLE #EarningsTableau
	select 
		StartDate
		, nomineefanid
		, SUM(DDEarnings + MobileLoginEarnings) AS Earnings
		, CalculationDate
	INTO #EarningsTableau
	from warehouse.relational.Reward3Point0_AccountEarnings
	GROUP BY StartDate, NomineeFanID, CalculationDate
	--order by startdate

	CREATE CLUSTERED INDEX CIX ON #EarningsTableau (NomineeFanID)


	IF OBJECT_ID('tempdb..#EarningsFinance') IS NOT NULL 
		DROP TABLE #EarningsFinance
	select 
		DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0) MonthDate
		, sum(earnings) Earnings
		, FanID
	INTO #EarningsFinance
	from Finance.dbo.Transactions
	where AdditionalCashbackAwardTypeID in (37, 38)
	GROUP BY 
		DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0)
		, FanID

	IF OBJECT_ID('tempdb..#EarningsProd') IS NOT NULL 
		DROP TABLE #EarningsProd
	SELECT
		DATEADD(MONTH, DATEDIFF(MONTH, 0, Date), 0) MonthDate
		, SUM(Clubcash) AS Earnings
		, FanID
	INTO #EarningsProd
	FROM SLC_Repl..Trans t
	WHERE TypeID IN (29, 31)
	GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, Date), 0)
		, FanID

	SELECT
		x.Earnings AS Tableau
		, y.Earnings AS Finance
		, z.Earnings AS Prod
		, TableauVSFinance = x.Earnings - y.Earnings
		, TableauVSProd = x.Earnings - z.Earnings
		, FinanceVSProd = y.Earnings - z.Earnings
		, x.MonthDate
		, y.MOnthDate
		, z.MonthDate
	FROM (
		SELECT SUM(Earnings), StartDate AS MonthDate
		FROM #EarningsTableau
		GROUP BY StartDate
	) x(Earnings,MonthDate)
	FULL OUTER JOIN (
		SELECT SUM(Earnings), MonthDate
		FROM #EarningsFinance
		GROUP BY MonthDate
	) y(Earnings, MOnthDate)
		ON x.MonthDate = y.MOnthDate
	FULL OUTER JOIN (
		SELECT SUM(Earnings), MonthDate
		FROM #EarningsProd
		GROUP BY MonthDate
	) z(Earnings, MonthDate)
		ON x.MonthDate = z.MonthDate
		OR y.MOnthDate = z.MonthDate
	ORDER BY x.MonthDate

END