-- =============================================
-- Author:		JEA
-- Create date: 15/04/2014
-- Description:	Spend and Earning figures for CBP Monthly Dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_SpendEarn_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT SpendThisMonthRBS, EarnedThisMonthRBS, SpendersThisMonthRBS, TransactionsThisMonthRBS, SpendYearRBS, EarnedYearRBS, SpendersYearRBS, TransactionsYearRBS
		, SpendThisMonthCoalition, EarnedThisMonthCoalition, SpendersThisMonthCoalition, TransactionsThisMonthCoalition
		, SpendYearCoalition, EarnedYearCoalition, SpendersYearCoalition, TransactionsYearCoalition
		, CoalitionCustomersMonthAverage, CoalitionCustomersYear
	FROM MI.CBPDashboard_Month_SpendEarn
	
END
