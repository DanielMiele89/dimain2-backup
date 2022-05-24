-- =============================================
-- Author:		JEA
-- Create date: 26/06/2013
-- Description:	Retrieves a list of all emails
-- CJM 20161116 No easy tuning opportunity here
-- =============================================
CREATE PROCEDURE [RBSMIPortal].[Email_WarehouseStage_Fetch] 
	with execute as owner
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
	where ea.ID > 432994026
    
END