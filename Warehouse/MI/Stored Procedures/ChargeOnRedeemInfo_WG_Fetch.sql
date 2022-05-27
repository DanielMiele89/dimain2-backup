-- =============================================
-- Author:		JEA
-- Create date: 25/11/2014
-- Description:	Retrieves the most recent set of charges on redemption - Williams & Glyn Version
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeemInfo_WG_Fetch]

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
	FROM MI.EarnRedeemFinance_RBSFundedReportInfo_WG

END
