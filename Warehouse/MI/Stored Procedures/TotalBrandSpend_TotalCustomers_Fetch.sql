-- =============================================
-- Author:		JEA
-- Create date: 07/02/2014
-- Description:	Sources customer grand totals for the Total Brand Spend report
-- =============================================
CREATE PROCEDURE MI.TotalBrandSpend_TotalCustomers_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT TotalCustomerCountThisYear
		, TotalOnlineCustomerCountThisYear
		, TotalCustomerCountLastYear
		, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers

END