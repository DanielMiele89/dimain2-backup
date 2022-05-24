-- =============================================
-- Author:		JEA
-- Create date: 24/10/2014
-- Description:	Ensures that redemptions do not
-- show has having been deducted from ineligible earnings
-- =============================================
CREATE PROCEDURE MI.EarnRedeemFinance_CheckEligible 
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE MI.EarnRedeemFinance_Totals
	SET Earnings = 0, EligibleEarnings = 0, IneligibleEarnings = 0
	WHERE PaymentMethodID = 200 --unallocated redemptions

	UPDATE MI.EarnRedeemFinance_Totals
	SET IneligibleEarnings = IneligibleEarnings + (EligibleEarnings - RedemptionValue)
		, EligibleEarnings = RedemptionValue
	WHERE (EligibleEarnings - RedemptionValue) < 0
	AND PaymentMethodID != 200

	UPDATE MI.EarnRedeemFinance_Totals 
	SET IneligibleEarnings = 0
	WHERE IneligibleEarnings < 0

END