
-- =============================================
-- Author:		JEA
-- Create date: 11/03/2014
-- Description:	Sources USP statistics report main section
-- =============================================
CREATE PROCEDURE [MI].[USPStatistics_FetchTotalsHayden] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT StatsDate
		, SpendTotal
		, EarningsTotal
		, MaleCount
		, FemaleCount
		, CBPActiveCustomers
		, PublisherName
	FROM MI.USP_Hayden
	WHERE StatsDate = (SELECT MAX(StatsDate) FROM MI.USPStatistics)
	AND PublisherName <> '~'

END