-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Spend and Earning figures for CBP Weekly Dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_SpendEarn_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT SpendThisWeekRBS, EarnedThisWeekRBS, SpendersThisWeekRBS, TransactionsThisWeekRBS, SpendLastWeekRBS, EarnedLastWeekRBS, SpendersLastWeekRBS
		, TransactionsLastWeekRBS, SpendYearRBS, EarnedYearRBS, SpendersYearRBS, TransactionsYearRBS, SpendThisWeekCoalition, EarnedThisWeekCoalition, SpendersThisWeekCoalition, TransactionsThisWeekCoalition
		, SpendLastWeekCoalition, EarnedLastWeekCoalition, SpendersLastWeekCoalition, TransactionsLastWeekCoalition, SpendYearCoalition, EarnedYearCoalition, SpendersYearCoalition, TransactionsYearCoalition
		, CoalitionCustomersMonthToDate, CoalitionCustomersMonthAverage, CoalitionCustomersYear
		, TransactionsThisWeekRBSContactless, TransactionsLastWeekRBSContactless, TransactionsYearRBSContactless
		, TransactionsThisWeekCoalitionContactless, TransactionsLastWeekCoalitionContactless, TransactionsYearCoalitionContactless
	FROM MI.CBPDashboard_Week_SpendEarn
	
END