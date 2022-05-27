-- =============================================
-- Author:		JEA
-- Create date: 25/11/2014
-- Description:	deals with negative eligiblity totals
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBS_Totals_WG_Fix] 
	
AS
BEGIN

	SET NOCOUNT ON;

	--where redemptions have made eligible earnings negative,
	--they must have taken place but then dropped a customer below eligibility
	UPDATE MI.EarnRedeemFinance_RBS_Totals_WG
		SET EligibleEarnings = 0
			, IneligibleEarnings = IneligibleEarnings + EligibleEarnings
	WHERE EligibleEarnings < 0

	UPDATE MI.EarnRedeemFinance_RBS_Totals_WG
		SET NoLiability = Earnings - RedemptionValue - EligibleEarnings - IneligibleEarnings

	UPDATE MI.EarnRedeemFinance_RBS_Totals_Month_WG
	SET EligibleEarnings = 0
		, IneligibleEarnings = IneligibleEarnings + EligibleEarnings
	WHERE EligibleEarnings < 0

END
