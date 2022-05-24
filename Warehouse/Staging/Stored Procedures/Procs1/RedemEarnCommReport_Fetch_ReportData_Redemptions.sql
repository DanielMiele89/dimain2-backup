/******************************************************************************
Author: Jason Shipp
Created: 18/06/2018
Purpose:
	- Fetch redemption report data for Redemption Earnings Communications Report
		
------------------------------------------------------------------------------
Modification History

Jason Shipp 29/08/2018
	- Added logic to use linear regression to fetch forecast of summary data for future months

Jason Shipp 23/01/2019
	- Adapted Summary logic to cope with more than 2 IsSummary flags, to support additional summary data by month (not by rolling months)

Jason Shipp 01/02/2019
	- Updated ColourHexCodes to match new brand colours

******************************************************************************/
CREATE PROCEDURE Staging.RedemEarnCommReport_Fetch_ReportData_Redemptions
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MaxReportDate date = (SELECT MAX(ReportDate) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions);

	-- Load RedemptionsCount colour mapping

	IF OBJECT_ID('tempdb..#RedemCountColours') IS NOT NULL DROP TABLE #RedemCountColours;

	WITH c AS (
		SELECT
			x.RedemptionsCount 
			, ROW_NUMBER() OVER (ORDER BY x.RedemptionsCount) AS RowNum
		FROM (
			SELECT DISTINCT 
				RedemptionsCount 
			FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions
			WHERE
				ReportDate = @MaxReportDate
				AND RedemptionsCount IS NOT NULL
		) x
	)
	SELECT
		RedemptionsCount 
		, CASE col.ColourHexCode WHEN '#4b196e' THEN '#1e5cc0' WHEN '#dc0f50' THEN '#ea0c5c' ELSE col.ColourHexCode END AS ColourHexCode  
	INTO #RedemCountColours
	FROM c
	LEFT JOIN Warehouse.APW.ColourList col
		ON c.RowNum = col.ID;

	-- Load base report data

	IF OBJECT_ID('tempdb..#RedemDatStaging') IS NOT NULL DROP TABLE #RedemDatStaging;
	
	SELECT
		d.ID
		, d.PeriodID
		, d.RollingMonthStart
		, d.RollingMonthEnd
		, d.BookTypeValue
		, d.PaymentMethodsAvailableID
		, CASE 
			WHEN d.BookTypeValue = 'F' AND d.PaymentCardMethod = 'Debit and Credit' THEN 'Reward Current Account - Debit and Credit'
			WHEN d.BookTypeValue = 'F' AND d.PaymentCardMethod = 'Debit Only' THEN 'Reward Current Account - Debit Only'
			WHEN d.BookTypeValue = 'B' AND d.PaymentCardMethod = 'Credit Only' THEN 'Reward Credit Card (but no Reward Current Account) - Credit Only' 
			WHEN d.BookTypeValue = 'B' AND d.PaymentCardMethod = 'Debit and Credit' THEN 'Reward Credit Card (but no Reward Current Account) - Debit and Credit' 
			WHEN d.BookTypeValue = 'B' AND d.PaymentCardMethod = 'Debit Only' THEN 'Cashback Plus - Debit Only'
			ELSE NULL
		END AS AccountPaymentTypeGroup
		, CASE 
			WHEN d.BookTypeValue = 'F' AND d.PaymentCardMethod = 'Debit and Credit' THEN 1
			WHEN d.BookTypeValue = 'F' AND d.PaymentCardMethod = 'Debit Only' THEN 2
			WHEN d.BookTypeValue = 'B' AND d.PaymentCardMethod = 'Credit Only' THEN 3
			WHEN d.BookTypeValue = 'B' AND d.PaymentCardMethod = 'Debit and Credit' THEN 4 
			WHEN d.BookTypeValue = 'B' AND d.PaymentCardMethod = 'Debit Only' THEN 5
			ELSE NULL
		END AS AccountPaymentTypeGroupOrder
		, d.DebitFlag
		, d.CreditFlag
		, d.PaymentCardMethod
		, d.RedemptionsCount
		, d.ActiveCustomers
		, d.RedeemersCount12M
		, d.YTDRedeemersCount
		, d.IsSummary
		, d.ReportDate
		, SUM(d.RedeemersCount12M) OVER (
			PARTITION BY d.PeriodID, d.RollingMonthStart, d.RollingMonthEnd, d.BookTypeValue, d.PaymentMethodsAvailableID, d.DebitFlag, d.CreditFlag, d.PaymentCardMethod
			ORDER BY d.RedemptionsCount DESC
		) AS CumulativeRedeemersCount12M
		, col.ColourHexCode AS RedemCountColourHexCode
	INTO #RedemDatStaging
	FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions d
	LEFT JOIN #RedemCountColours col
		ON d.RedemptionsCount = col.RedemptionsCount
	WHERE
		(
			(IsSummary = 0 AND d.BookTypeValue IS NOT NULL AND d.PaymentCardMethod <> 'None'
			AND NOT (d.BookTypeValue = 'F' AND d.PaymentCardMethod = 'Credit Only' ))
			OR (IsSummary >= 1)
		)
		AND d.ReportDate = @MaxReportDate;

	-- Load parameter values for regression model of summary data
	-- Regression formulas here: http://janda.org/c10/Lectures/topic04/L25-Modeling.htm

	IF OBJECT_ID('tempdb..#RegressionParams') IS NOT NULL DROP TABLE #RegressionParams;

	WITH RedemCustDat AS (
		SELECT
			ROW_NUMBER() OVER (ORDER BY RollingMonthStart) AS x
			, CumulativeRedeemersCount12M
			, ActiveCustomers
		FROM #RedemDatStaging
		WHERE
			IsSummary = 1
			AND RedemptionsCount = 1
	)
	SELECT
		GradientRedeemers
		, ybarRedeemers - (xbar * GradientRedeemers) AS InterceptRedeemers
		, GradientActiveCust
		, ybarActiveCust - (xbar * GradientActiveCust) AS InterceptActiveCust
	INTO #RegressionParams
	FROM
		(
			SELECT
				SUM((x - xbar) * (yRedeemers - ybarRedeemers)) / SUM((x - xbar) * (x - xbar)) AS GradientRedeemers
				, MAX(ybarRedeemers) AS ybarRedeemers
				, SUM((x - xbar) * (yActiveCust - ybarActiveCust)) / SUM((x - xbar) * (x - xbar)) AS GradientActiveCust
				, MAX(ybarActiveCust) AS ybarActiveCust
				, MAX(xbar) AS xbar
			FROM
				(
					SELECT
						AVG(CumulativeRedeemersCount12M) OVER(ORDER BY (SELECT NULL)) AS ybarRedeemers
						, CumulativeRedeemersCount12M AS yRedeemers
						, AVG(ActiveCustomers) OVER(ORDER BY (SELECT NULL)) AS ybarActiveCust
						, ActiveCustomers AS yActiveCust
						, AVG(x) OVER(ORDER BY (SELECT NULL)) AS xbar
						, x
					FROM
						RedemCustDat
				) a
		) b;

	-- Set parameter values for regression model of summary data

	DECLARE @GradientRedeemers float = (SELECT GradientRedeemers FROM #RegressionParams);
	DECLARE @InterceptRedeemers float = (SELECT InterceptRedeemers FROM #RegressionParams);
	DECLARE @GradientActiveCust float = (SELECT GradientActiveCust FROM #RegressionParams);
	DECLARE @InterceptActiveCust float = (SELECT InterceptActiveCust FROM #RegressionParams);
	DECLARE @MaxSummaryDate date = (SELECT MAX(RollingMonthStart) FROM #RedemDatStaging WHERE IsSummary = 1 AND RedemptionsCount = 1);
	DECLARE @MaxPeriodID int = (SELECT MAX(PeriodID) FROM #RedemDatStaging WHERE IsSummary = 1 AND RedemptionsCount = 1);

	-- Load main report data

	WITH E1 AS (SELECT n = 0 FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) d (n))
	, Tally AS (SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E1) -- Tally table; minus 1 to start at 0
	, TallyDates AS (SELECT n, DATEADD(month, n, @MaxSummaryDate) AS RollingMonthStart FROM Tally)

	SELECT
		s.ID
		, s.PeriodID
		, s.RollingMonthStart
		, s.RollingMonthEnd
		, s.BookTypeValue
		, s.PaymentMethodsAvailableID
		, s.AccountPaymentTypeGroup
		, s.AccountPaymentTypeGroupOrder
		, s.DebitFlag
		, s.CreditFlag
		, s.PaymentCardMethod
		, s.RedemptionsCount
		, s.ActiveCustomers
		, s.RedeemersCount12M
		, s.YTDRedeemersCount
		, s.IsSummary
		, s.ReportDate
		, s.CumulativeRedeemersCount12M
		, s.RedemCountColourHexCode
		, CAST(0 AS bit) AS IsForecast
	FROM #RedemDatStaging s

	UNION ALL

	-- Load summary report data forecast

	SELECT 
		NULL AS ID
		, NULL AS PeriodID
		, t.RollingMonthStart
		, EOMONTH(DATEADD(month, 11, t.RollingMonthStart)) AS RollingMonthEnd
		, NULL AS BookTypeValue
		, NULL AS PaymentMethodsAvailableID
		, NULL AS AccountPaymentTypeGroup
		, NULL AS AccountPaymentTypeGroupOrder
		, NULL AS DebitFlag
		, NULL AS CreditFlag
		, NULL AS PaymentCardMethod
		, 1 AS RedemptionsCount
		, (@GradientActiveCust*(n+@MaxPeriodID)) + @InterceptActiveCust AS ActiveCustomers -- y=mx+c
		, NULL AS RedeemersCount12M
		, NULL AS YTDRedeemersCount
		, CAST(1 as bit) AS IsSummary
		, @MaxReportDate AS ReportDate
		, (@GradientRedeemers*(n+@MaxPeriodID)) + @InterceptRedeemers AS CumulativeRedeemersCount12M -- y=mx+c
		, col.ColourHexCode AS RedemCountColourHexCode
		, CAST(1 AS bit) AS IsForecast
	FROM TallyDates t
	CROSS JOIN #RedemCountColours col
	WHERE 
		col.RedemptionsCount = 1;

END