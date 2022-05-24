-- =============================================
-- Author:		JEA
-- Create date: 12/09/2014
-- Description:	Penny for London Specific marketing email unsubscribes
-- =============================================
CREATE PROCEDURE RewardBI.PForL_MarketingEmail_ChangeLog_Fetch 
	(
		@LoadedDate DATETIME
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT m.FanID
		, m.MarketingEmailUnsubscribe
		, m.EventDate
		, m.AuditDate
	FROM MI.MarketingEmail_ChangeLog m
	INNER JOIN SLC_Report.dbo.Fan f ON m.FanID = f.ID
	WHERE f.ClubID = 141
	AND m.AuditDate > @LoadedDate

END