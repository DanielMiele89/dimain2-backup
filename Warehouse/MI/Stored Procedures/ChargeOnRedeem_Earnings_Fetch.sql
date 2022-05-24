-- =============================================
-- Author:		JEA
-- Create date: 30/07/2013
-- Description:	Retrieves list of customer earnings for reconciliation charg
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeem_Earnings_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT FanID, TransactionDate, EarnAmount,ChargeOnRedeem, BrandID
	FROM MI.ChargeOnRedeem_Earnings
	ORDER BY FanID, EligibleDate, ChargeTypeID --by agreement with Bhavesh Hirani, retailer cashback should be assessed first

END
