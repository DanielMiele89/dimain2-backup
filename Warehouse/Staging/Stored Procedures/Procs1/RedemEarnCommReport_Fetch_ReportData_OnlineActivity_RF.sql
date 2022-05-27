/******************************************************************************
Author: Jason Shipp
Created: 18/06/2018
Purpose:
	- Fetch online activity report data for Redemption Earnings Communications Report
		
------------------------------------------------------------------------------
Modification History

Jason Shipp 03/10/2018
	- Added load of future months to fetch to allow extension of summary plots

Jason Shipp 23/01/2019
	- Adapted Summary logic to cope with more than 2 IsSummary flags, to support additional summary data by month (not by rolling months)

******************************************************************************/
CREATE PROCEDURE [Staging].[RedemEarnCommReport_Fetch_ReportData_OnlineActivity_RF]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @MaxReportDate date = (SELECT MAX(ReportDate) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity_RF);
	DECLARE @MaxSummaryDate date = (SELECT MAX(MonthStart) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity_RF WHERE IsSummary >= 1);

	-- Load main report data
	;
	WITH E1 AS (SELECT n = 0 FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) d (n))
	, Tally AS (SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E1) -- Tally table; minus 1 to start at 0
	, TallyDates AS (SELECT n, DATEADD(month, n, @MaxSummaryDate) AS MonthStart FROM Tally)

	SELECT
		d.ID
		, d.PeriodID
		, d.YYYYMM
		, d.MonthStart
		, d.MonthEnd
		, CASE
			WHEN DATEPART(month, d.MonthEnd) = (
				SELECT DATEPART(month, MAX(MonthEnd)) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity_RF
				WHERE ReportDate = @MaxReportDate
			)
			THEN 1
			ELSE 0 
		END AS IsMaxMonth
		, d.BookTypeValue
		, d.PaymentCardMethod
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
		, d.MarketableByEmail
		, d.Registered
		, d.ActiveCustomers
		, d.EmailOpeners
		, d.WebsiteLogins_3M
		, d.WebsiteLogins_12M
		, d.IsSummary
		, d.ReportDate
		, CAST(0 AS bit) AS IsFuture
	INTO #ForReport
	FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity_RF d
	WHERE
		(
			(IsSummary = 0 AND d.BookTypeValue IS NOT NULL AND d.PaymentCardMethod <> 'None'
			AND NOT (d.BookTypeValue = 'F' AND d.PaymentCardMethod = 'Credit Only' ))
			OR (IsSummary >= 1)
		)
		AND d.ReportDate = @MaxReportDate

		
	SELECT	MonthGraph = CASE
							WHEN DATEPART(MONTH, MonthStart) IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) THEN CONVERT(DATE, '2021-' + CONVERT(VARCHAR(2), DATEPART(MONTH, MonthStart)) + '-' + CONVERT(VARCHAR(2), DATEPART(DAY, MonthStart)))
							ELSE CONVERT(DATE, '2020-' + CONVERT(VARCHAR(2), DATEPART(MONTH, MonthStart)) + '-' + CONVERT(VARCHAR(2), DATEPART(DAY, MonthStart)))
						END
		,	MonthLabel = CASE
							WHEN MonthStart <= '2020-12-01' THEN 'Jan 2020 - Dec 2020'
							ELSE 'Jan 2021 - Dec 2021'
						END
		,	*
	FROM #ForReport
	WHERE '2020-01-01' <= MonthStart
	ORDER BY MonthStart


	/*

	SELECT	MonthGraph
		,	MonthLabel
		,	YYYYMM
		,	MonthStart
		,	MonthEnd
		,	IsSummary
		,	IsFuture
		,	SUM(EmailOpeners) AS EmailOpeners
		,	SUM(CASE WHEN MarketableByEmail = 1 THEN ActiveCustomers ELSE 0 END) AS ActiveCustomers
	FROM (	SELECT	MonthGraph = CASE
									WHEN DATEPART(MONTH, MonthStart) IN (1,  2) THEN CONVERT(DATE, '2021-' + CONVERT(VARCHAR(2), DATEPART(MONTH, MonthStart)) + '-' + CONVERT(VARCHAR(2), DATEPART(DAY, MonthStart)))
									ELSE CONVERT(DATE, '2020-' + CONVERT(VARCHAR(2), DATEPART(MONTH, MonthStart)) + '-' + CONVERT(VARCHAR(2), DATEPART(DAY, MonthStart)))
								END
				,	MonthLabel = CASE
									WHEN MonthStart <= '2020-02-01' THEN 'Mar 2019 - Feb 2020'
									ELSE 'Mar 2020 - Feb 2021'
								END
				,	YYYYMM
				,	MonthStart
				,	MonthEnd
				,	EmailOpeners
				,	MarketableByEmail
				,	ActiveCustomers
				,	IsSummary
				,	IsFuture
			FROM #ForReport
			WHERE '2019-03-01' <= MonthStart
			AND IsSummary = 1) fr
	GROUP BY MonthGraph
		,	MonthLabel
		,	YYYYMM
		,	MonthStart
		,	MonthEnd
		,	IsSummary
		,	IsFuture
	ORDER BY MonthStart

	*/

END
