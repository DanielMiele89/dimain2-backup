/******************************************************************************
Author: Jason Shipp
Created: 18/06/2018
Purpose:
	- Fetch cashback report data for Redemption Earnings Communications Report
		
------------------------------------------------------------------------------
Modification History

Jason Shipp 01/02/2019
	- Updated ColourHexCodes to match new brand colours

******************************************************************************/
CREATE PROCEDURE Staging.RedemEarnCommReport_Fetch_ReportData_Cashback
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MaxReportDate date = (SELECT MAX(ReportDate) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Cashback);

	-- Load CashbackOrigin colour mapping

	IF OBJECT_ID('tempdb..#CashbackOriginColours') IS NOT NULL DROP TABLE #CashbackOriginColours;

	WITH c AS (
		SELECT
			x.CashbackOrigin
			, ROW_NUMBER() OVER (ORDER BY x.CashbackOrigin) AS RowNum
		FROM (
			SELECT DISTINCT 
				CashbackOrigin 
			FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Cashback
			WHERE
				ReportDate = @MaxReportDate
				AND CashbackOrigin IS NOT NULL
		) x
	)
	SELECT
		CashbackOrigin 
		, CASE col.ColourHexCode WHEN '#4b196e' THEN '#1e5cc0' WHEN '#dc0f50' THEN '#ea0c5c' ELSE col.ColourHexCode END AS ColourHexCode 
	INTO #CashbackOriginColours
	FROM c
	LEFT JOIN Warehouse.APW.ColourList col
		ON c.RowNum = col.ID;
	
	SELECT
		d.ID
		, d.PeriodID
		, d.MonthStart
		, d.MonthEnd
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
		, d.CashbackOrigin
		, d.ActiveCustomers
		, d.MonthCashbackEarners
		, d.MonthCashbackSum
		, d.ReportDate
		, col.ColourHexCode AS CashbackOriginColourHexCode
	FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Cashback d
	LEFT JOIN #CashbackOriginColours col
		ON d.CashbackOrigin = col.CashbackOrigin
	WHERE
		d.BookTypeValue IS NOT NULL
		AND d.PaymentCardMethod <> 'None'
		AND NOT (d.BookTypeValue = 'F' AND d.PaymentCardMethod = 'Credit Only' )
		AND d.ReportDate = @MaxReportDate;
	
END