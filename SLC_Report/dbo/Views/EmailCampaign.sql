CREATE VIEW dbo.EmailCampaign
AS
SELECT ID, CampaignKey, EmailKey, Folder, ListKey, ListName, QueryKey, QueryName, CampaignName
	, [Subject], SendDate, EmailsSent, EmailsDelivered, UniqueOpens, UniqueClicks, UniqueUnsubscribes, UniqueHardBounces, ImportDate
FROM SLC_Snapshot.dbo.EmailCampaign
GO
GRANT SELECT
    ON OBJECT::[dbo].[EmailCampaign] TO [Analyst]
    AS [dbo];

