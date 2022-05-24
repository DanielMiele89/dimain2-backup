-- =============================================
-- Author:		JEA
-- Create date: 29/08/2013
-- Description:	Retrieves the most recent set of charges on redemption
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeemInfo_Fetch]

AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT YearNumber
		, MonthNumber
		, PartnerID
		, PartnerName
		, EarnedTotalMonth
		, EarnedTotalCumulative
		, RedeemedTotalMonth
		, RedeemedTotalCumulative
		, EarnedEligibleMonth
		, EarnedEligibleCumulative
		, EarnedPendingMonth
		, EarnedPendingCumulative
		, EligibleCustomerCount
		, EligiblePendingCustomerCount
		, BankID
	FROM MI.EarnRedeemFinance_RBSFundedReportInfo

END
