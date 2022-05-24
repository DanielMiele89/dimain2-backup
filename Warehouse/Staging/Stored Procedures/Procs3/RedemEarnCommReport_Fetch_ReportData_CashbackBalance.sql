/******************************************************************************
Author: Jason Shipp
Created: 25/02/2019
Purpose:
	- Fetch cashback balance report data for Redemption Earnings Communications Report
		
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.RedemEarnCommReport_Fetch_ReportData_CashbackBalance
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MaxReportDate date = (SELECT MAX(ReportDate) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_CashbackBalance);

	SELECT 
		d.PeriodID
		, d.MonthEnd
		, d.PaymentCardMethod
		, d.Registered
		, d.Accounts
		, d.ClubCashPending
		, d.ReportDate
	FROM Warehouse.Staging.RedemEarnCommReport_ReportData_CashbackBalance d
	WHERE
		d.ReportDate = @MaxReportDate;
	
END