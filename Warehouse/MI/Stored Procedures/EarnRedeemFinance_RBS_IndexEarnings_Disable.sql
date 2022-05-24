-- =============================================
-- Author:		JEA
-- Create date: 14/11/2014
-- Description:	Disables earnings index prior to repopulation of the table
-- =============================================
CREATE PROCEDURE MI.EarnRedeemFinance_RBS_IndexEarnings_Disable
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    ALTER INDEX IX_EarnRedeemFinance_RBS_Earnings_Preaggregate ON MI.EarnRedeemFinance_RBS_Earnings DISABLE

END
