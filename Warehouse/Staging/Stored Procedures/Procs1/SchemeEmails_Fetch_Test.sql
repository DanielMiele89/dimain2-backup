-- =============================================
-- Author:		JEA
-- Create date: 26/06/2013
-- Description:	Retrieves a list of all emails
-- Edited: Adam Scott adding clicks 24/03/2014
-- =============================================
Create PROCEDURE [Staging].[SchemeEmails_Fetch_Test] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT ea.ID
		, ec.CampaignKey
		, ea.FanID
		, CAST(ea.DeliveryDate AS DATE) as SendDate
		, ea.OpenDate
		, ea.ClickDate
		, ea.UnsubscribeDate
		, ea.HardBounceDate
		, ea.SoftBounceDate
	FROM slc_report.dbo.EmailActivity ea
	INNER JOIN Relational.EmailCampaign ec on ea.EmailCampaignID = ec.ID
	INNER JOIN Relational.CampaignLionSendIDs cl on ec.CampaignKey = cl.CampaignKey
    
END
