-- =============================================
-- Author:		JEA
-- Create date: 14/11/2014
-- Description:	Rebuilds earnings index following repopulation of the table
-- =============================================
CREATE PROCEDURE MI.EarnRedeemFinance_RBS_IndexEarnings_Rebuild
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    ALTER INDEX IX_EarnRedeemFinance_RBS_Earnings_Preaggregate ON MI.EarnRedeemFinance_RBS_Earnings REBUILD

END
