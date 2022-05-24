-- =============================================
-- Author:		JEA
-- Create date: 03/11/2014
-- Description:	deals with negative eligiblity totals
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_Totals_Fix] 
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE MI.EarnRedeemFinance_Totals
		SET Earnings = 0
			, EligibleEarnings = 0
			, IneligibleEarnings = 0
			, NoLiability = 0
	WHERE ChargeTypeID = 200 --UNASSIGNED REDEMPTION

	--where redemptions have made eligible earnings negative,
	--they must have taken place but then dropped a customer below eligibility
	UPDATE MI.EarnRedeemFinance_Totals
		SET EligibleEarnings = 0
			, IneligibleEarnings = IneligibleEarnings + EligibleEarnings
	WHERE EligibleEarnings < 0

	UPDATE MI.EarnRedeemFinance_Totals
		SET NoLiability = Earnings - RedemptionValue - EligibleEarnings - IneligibleEarnings
	WHERE ChargeTypeID != 200

END