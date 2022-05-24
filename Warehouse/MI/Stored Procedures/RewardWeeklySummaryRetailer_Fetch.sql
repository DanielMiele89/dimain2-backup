-- =============================================
-- Author:		JEA
-- Create date: 04/07/2014
-- Description:	Returns weekly retailer summary information
-- designed to return results according to a data-driven subscription


-- Edited by: HR
-- Edit Date: 08/04/2015
-- Changes:
	-- Added ORDER BY clause to account for 6 weekly reports
-- =============================================
CREATE PROCEDURE [MI].[RewardWeeklySummaryRetailer_Fetch]
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
	ORDER BY WeekStartDate DESC


END