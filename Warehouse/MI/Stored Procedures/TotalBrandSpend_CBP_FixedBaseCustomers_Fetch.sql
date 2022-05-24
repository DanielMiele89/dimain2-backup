-- =============================================
-- Author:		JEA
-- Create date: 28/05/2014
-- Alter date: 20/10/2016
-- Description:	Sources fixed base customer grand totals for the Total Brand Spend report - CBP version
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_CBP_FixedBaseCustomers_Fetch] 
	(
		@MyRewardsDataSet TINYINT
	)
AS
BEGIN

	SET NOCOUNT ON;

	IF @MyRewardsDataSet = 2
	BEGIN
		SELECT TotalCustomerCountThisYear
			, TotalOnlineCustomerCountThisYear
			, TotalCustomerCountLastYear
			, TotalOnlineCustomerCountLastYear
		FROM MI.GrandTotalCustomersFixedBase_CBP -- MyRewards customers regardless of core/private status
	END
	ELSE IF @MyRewardsDataSet = 1
	BEGIN
		SELECT TotalCustomerCountThisYear
			, TotalOnlineCustomerCountThisYear
			, TotalCustomerCountLastYear
			, TotalOnlineCustomerCountLastYear
		FROM MI.GrandTotalCustomersFixedBase_MyRewards_CorePrivate
		WHERE IsPrivate = 1 --Private
	END
	ELSE --@MyRewardsDataSet = 0
	BEGIN
		SELECT TotalCustomerCountThisYear
			, TotalOnlineCustomerCountThisYear
			, TotalCustomerCountLastYear
			, TotalOnlineCustomerCountLastYear
		FROM MI.GrandTotalCustomersFixedBase_MyRewards_CorePrivate
		WHERE IsPrivate = 0 --Core
	END

END
