CREATE VIEW dbo.EmailEvent
AS
SELECT ID, [Date], FanID, CampaignKey, EmailEventCodeID, ImportedDate, Processed
FROM SLC_Snapshot.dbo.EmailEvent
GO
GRANT SELECT
    ON OBJECT::[dbo].[EmailEvent] TO [Analyst]
    AS [dbo];

