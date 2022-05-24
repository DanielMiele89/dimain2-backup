-- =============================================
-- Author:		JEA
-- Create date: 25/06/2014
-- Description:	Sources earnings for EarnRedeemFinance report
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_Earnings_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT ID, FanID, TransactionDate, EarnRedeemable AS EarnAmount, BrandID, ChargeTypeID
		, PaymentMethodID
	FROM MI.EarnRedeemFinance_Earnings
	WHERE EarnRedeemable > 0
	ORDER BY FanID, TransactionDate

END
