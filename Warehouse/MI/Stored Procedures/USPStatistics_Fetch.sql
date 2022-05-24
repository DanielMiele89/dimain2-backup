-- =============================================
-- Author:		JEA
-- Create date: 11/03/2014
-- Description:	Sources USP statistics report main section
-- =============================================
CREATE PROCEDURE [MI].[USPStatistics_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT StatsDate
		, TotalTransactions
		, TotalTransactionsLastYear
		, TotalTransactionsLastMonth
		, SchemeActivations
		, SpendTotal
		, EarningsTotal
		, SectorCount
		, BrandCount
		, CardholderCount
		, AverageUpliftMonth
		, AverageUpliftLaunch
		, AverageSalesROIMonth
		, AverageSalesROILaunch
		, IncrementalSalesTotal
		, UpliftedSalesTotal
		, TopSalesROI
		, TopFinancialROI
		, MaleCount
		, FemaleCount
		, CBPActiveCustomers
	FROM MI.USPStatistics
	WHERE ID = (SELECT MAX(ID) FROM MI.USPStatistics)

END