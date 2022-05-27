-- =============================================
-- Author:		JEA
-- Create date: 26/06/2013
-- Description:	Retrieves a list of all emails
-- =============================================
CREATE PROCEDURE [RBSMIPortal].[Email_Fetch] 
	
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
	FROM RBSMIPortal.Staging_Email e
	INNER JOIN RBSMIPortal.Customer c ON e.FanID = c.FanID
	INNER JOIN RBSMIPortal.CalendarWeekMonth w ON e.SendDate = w.CalendarDate
    
END
