-- =============================================
-- Author:		JEA
-- Create date: 14/11/2014
-- Description:	Sources earnings for EarnRedeemFinance report
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBS_EarningsToCharge_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT e.ID, e.FanID, e.TransactionDate, e.EarnRedeemable AS EarnAmount, e.BrandID, e.ChargeTypeID
		, e.PaymentMethodID
	FROM MI.EarnRedeemFinance_RBS_Earnings e
	INNER JOIN  MI.EarnRedeemFinance_RBS_CustomersRedeemed r ON e.FanID = r.FanID
	WHERE e.EarnRedeemable > 0
	ORDER BY FanID, TransactionDate

END
