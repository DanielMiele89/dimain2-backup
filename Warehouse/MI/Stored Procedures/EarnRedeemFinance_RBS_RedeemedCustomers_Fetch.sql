-- =============================================
-- Author:		JEA
-- Create date: 14/11/2014
-- Description:	Sources earnings for EarnRedeemFinance report
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBS_RedeemedCustomers_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT DISTINCT FanID
	FROM MI.EarnRedeemFinance_RBS_Redemptions

END
