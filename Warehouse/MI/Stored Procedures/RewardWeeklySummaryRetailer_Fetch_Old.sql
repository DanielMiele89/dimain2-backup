
-- =============================================
-- Author:		JEA
-- Create date: 04/07/2014
-- Description:	Returns weekly retailer summary information
-- designed to return results according to a data-driven subscription
-- =============================================
CREATE PROCEDURE [MI].[RewardWeeklySummaryRetailer_Fetch_Old]
	(
		@PartnerID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT PartnerID
		, PartnerName
		, SalesWeek
		, SalesCumul
		, TranCountWeek
		, TranCountCumul
		, UniqueSpendersWeek
		, UniqueSpendersCumul
		, TargetedCustomersWeek
		, TargetedCustomersCumul
		, CommissionWeek
		, CommissionCumul
		, WeekStartDate
		, WeekEndDate
		, CumulativeDate
		, SalesWeekOnline
		, SalesCumulOnline
		, CommissionWeekOnline
		, CommissionCumulOnline
	FROM MI.RewardWeeklySummary
	WHERE PartnerID = @PartnerID

END