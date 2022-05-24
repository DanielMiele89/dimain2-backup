-- =============================================
-- Author:		JEA
-- Create date: 16/06/2015
-- Description:	Retrieves a list of all emails
-- =============================================
CREATE PROCEDURE [RBSMIPortal].[Email_SchemeMembership_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT e.ID
		, e.CampaignKey
		, e.FanID
		, e.SendDate
		, e.IsDelivered
		, e.IsOpened
		, e.IsUnsubscribed
		, e.IsClicked
		, w.TranWeekID AS SendWeekID
		, c.GenderID
		, c.AgeBandID
		, c.BankID
		, c.RainbowID
		, c.ChannelPreferenceID
		, c.ActivationMethodID
		, s.SchemeMembershipTypeID
	FROM RBSMIPortal.Staging_Email e
	INNER JOIN RBSMIPortal.Customer c ON e.FanID = c.FanID
	INNER JOIN RBSMIPortal.CalendarWeekMonth w ON e.SendDate = w.CalendarDate
	LEFT OUTER JOIN Relational.Customer_SchemeMembership s ON e.FanID = s.FanID AND e.SendDate >= s.StartDate AND (s.EndDate IS NULL OR e.SendDate <= s.EndDate) 
    
END
