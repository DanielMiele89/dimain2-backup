-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Redemption figures for CBP Weekly Dashboard
-- =============================================
CREATE PROCEDURE MI.CBPDashboard_Week_Redemptions_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT CashCountThisWeek, TradeUpCountThisWeek, CharityCountThisWeek, CashCountLastWeek, TradeUpCountLastWeek
		, CharityCountLastWeek, CashCountYear, TradeUpCountYear, CharityCountYear, RedeemValueYear
	FROM MI.CBPDashboard_Week_Redemptions

END
