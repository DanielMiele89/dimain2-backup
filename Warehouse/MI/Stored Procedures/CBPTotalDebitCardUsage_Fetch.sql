-- =============================================
-- Author:		JEA
-- Create date: 05/08/2014
-- Description:	Retrieves monthly spend by CBP customers in MI.CBPTotalDebitCardUsage
-- =============================================
CREATE PROCEDURE [MI].[CBPTotalDebitCardUsage_Fetch]

AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT GeneratedDate
		, MonthDate
		, ActiveCustomerCount
		, SpendingCustomerCount
		, Spend
		, ISNULL(LAG(ActiveCustomerCount, 1) OVER (ORDER BY MonthDate),0) AS ActiveCustomerPrev
		, ISNULL(LAG(Spend, 1) OVER (ORDER BY MonthDate),0) AS SpendPrev
		, ActiveCustomerTotal
		, SpendingCustomerTotal
	FROM MI.CBPTotalDebitCardUsage
	ORDER BY MonthDate DESC

END
