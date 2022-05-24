-- =============================================
-- Author:		JEA
-- Create date: 11/02/2014
-- Description:	Sources fixed base customer grand totals for the Total Brand Spend report
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_FixedBaseCustomers_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT TotalCustomerCountThisYear
		, TotalOnlineCustomerCountThisYear
		, TotalCustomerCountLastYear
		, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomersFixedBase

END