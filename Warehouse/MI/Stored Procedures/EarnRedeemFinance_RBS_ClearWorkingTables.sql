-- =============================================
-- Author:		JEA
-- Create date: 13/11/2014
-- Description:	Clears working tables for EarnRedeemFinance ETL Process
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBS_ClearWorkingTables]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE MI.EarnRedeemFinance_RBS_Earnings
	TRUNCATE TABLE MI.EarnRedeemfinance_RBS_Redemptions
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_RedemptionCharge
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_CustomerEligible
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_Totals
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_Totals_Month
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_CustomersRedeemed
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_EligibleCustomers
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_EligibleCustomersTotal
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_EligibleCustomers_WG
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_EligibleCustomersTotal_WG
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_Totals_Month_WG
	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_Totals_WG

END