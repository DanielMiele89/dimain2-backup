-- =============================================
-- Author:		JEA
-- Create date: 26/03/2014
-- Description:	Fetches the weekly measurements
-- for the daily scheme stats report
-- =============================================
CREATE PROCEDURE [MI].[SchemeStats_Weekly_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

    SELECT StartDate
		, EndDate
		, Spend
		, Earnings
		, TransactionCount
		, CustomerCount
	FROM MI.SchemeStats_Weekly_TranDate
	ORDER BY StartDate DESC

END