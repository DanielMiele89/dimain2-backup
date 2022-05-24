-- =============================================
-- Author:		JEA
-- Create date: 19/12/2013
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeem_CustomerTotals_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT EligibleCountNatWest AS EligibleCustomerCountNatWest
		, EarnedCountNatWest AS EligiblePendingCustomerCountNatWest
		, EliglbleCountRBS AS EligibleCustomerCountRBS
		, EarnedCountRBS AS EligiblePendingCustomerCountRBS
	FROM MI.EarnRedeemFinance_RBS_EligibleCustomersTotal

END