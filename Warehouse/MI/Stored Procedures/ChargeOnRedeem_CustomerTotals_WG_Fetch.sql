-- =============================================
-- Author:		JEA
-- Create date: 25/11/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeem_CustomerTotals_WG_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT EligibleCountNatWest AS EligibleCustomerCountNatWest
		, EarnedCountNatWest AS EligiblePendingCustomerCountNatWest
		, EliglbleCountRBS AS EligibleCustomerCountRBS
		, EarnedCountRBS AS EligiblePendingCustomerCountRBS
	FROM MI.EarnRedeemFinance_RBS_EligibleCustomersTotal_WG

END