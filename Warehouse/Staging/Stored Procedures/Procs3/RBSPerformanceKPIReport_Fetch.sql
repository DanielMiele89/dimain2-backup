/******************************************************************************
Author: Jason Shipp
Created: 28/03/2019
Purpose: 
	- Fetch metrics for RBS Performance KPI Report
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/04/2019
	- Added parameter to identify whether to fetch all/credit-card-only results

******************************************************************************/
CREATE PROCEDURE Staging.RBSPerformanceKPIReport_Fetch (@IsCreditCardResults bit) 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MaxReportDate date = (SELECT MAX(ReportDate) FROM Warehouse.Staging.RBSPerformanceKPIReport_Results WHERE IsCreditCardResults = @IsCreditCardResults)

	SELECT
		d.ReportDate
		, d.PeriodType
		, d.StartDate
		, d.EndDate
		, d.ActiveCustomers
		, d.NewActiveCustomersYTD
		, d.ActiveCreditCardCustomers
		, d.NewActiveCreditCardCustomersYTD
		, d.ActiveCustomerSpend
		, d.AverageActiveCustomerSpend
		, d.PartnerCashbackEarned
		, d.BankFundedCashbackEarned
		, d.TotalCashbackEarned
		, d.AveragePartnerCashbackEarned
		, d.AverageBankFundedCashbackEarned
		, d.AverageTotalCashbackEarned
		, d.Redemptions
		, d.CashValueRedeemed
		, d.AverageCustomerRedemptions
		, d.AverageCustomerCashValueRedeemed
		, d.CashValueRedeemedProportionOfTotalEarned
		, d.Redeemers
		, d.FirstTimeRedeemers
		, d.ProportionFirstTimeRedeemers
		, d.ProportionCashRedemptions
		, d.ProportionTradeUpRedemptions
		, d.ProportionCharityRedemptions
		, d.ProportionActiveCustomersRedeemed
		, d.Logins
		, d.CustomersWhoLoggedIn
		, d.ProportionActiveCustomersLoggedIn
		, d.AverageActiveCustomerLogins
		, d.Registrations
		, d.RegisteredCustomers
		, d.ProportionActiveCustomersRegistered
		, d.MarketableCustomers
		, d.ProportionActiveCustomersMarketable
		, d.ActiveCustomersRegisteredMarketable
		, d.ProportionActiveCustomersRegisteredMarketable
	FROM Warehouse.Staging.RBSPerformanceKPIReport_Results d
	WHERE 
		d.ReportDate = @MaxReportDate
		AND d.IsCreditCardResults = @IsCreditCardResults
	ORDER BY d.StartDate;

END