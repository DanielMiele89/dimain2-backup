-- =============================================
-- Author:		JEA
-- Create date: 17/08/2016
-- Description:	Fetches old weekly summary results
-- =============================================
CREATE PROCEDURE APW.TargetedCustomersCompare_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT PartnerID AS RetailerID, WeekStartDate, TargetedCustomersWeek, TargetedCustomersCumul
	FROM MI.RewardWeeklySummary
	ORDER BY PartnerID, WeekStartDate

END
