
-- =============================================
-- Author:		JEA
-- Create date: 11/03/2014
-- Description:	Sources USP statistics report main section
-- =============================================
CREATE PROCEDURE [MI].[USPStatistics_FetchHayden] 
	
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
		, PublisherName
	FROM MI.USP_Hayden
	WHERE StatsDate = (SELECT MAX(StatsDate) FROM MI.USPStatistics)

END

