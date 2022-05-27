-- =============================================
-- Author:		JEA
-- Create date: 26/06/2014
-- Description:	Clears working tables for EarnRedeemFinance ETL Process
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_ClearWorkingTables]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE MI.EarnRedeemFinance_Earnings
	TRUNCATE TABLE MI.EarnRedeemfinance_Redemptions
	TRUNCATE TABLE MI.EarnRedeemFinance_RedemptionCharge
	TRUNCATE TABLE MI.EarnRedeemFinance_CustomerEligible
	TRUNCATE TABLE MI.EarnRedeemFinance_EarnRedeemByMonth
	TRUNCATE TABLE MI.EarnRedeemFinance_Totals
	TRUNCATE TABLE MI.EarnRedeemFinance_CrossCheck_PartnerEarnings
	TRUNCATE TABLE MI.EarnRedeemFinance_CrossCheck_CashbackAwards
	TRUNCATE TABLE MI.EarnRedeemFinance_CrossCheck_AdditionalEarnings

END
