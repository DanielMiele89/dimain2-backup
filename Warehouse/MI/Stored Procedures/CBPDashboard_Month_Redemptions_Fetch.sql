-- =============================================
-- Author:		JEA
-- Create date: 15/04/2014
-- Description:	Redemption figures for CBP Monthly Dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_Redemptions_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT CashCountThisMonth, TradeUpCountThisMonth, CharityCountThisMonth
		, CashCountYear, TradeUpCountYear, CharityCountYear, RedeemValueYear
	FROM MI.CBPDashboard_Month_Redemptions

END