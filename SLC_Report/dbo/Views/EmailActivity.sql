CREATE VIEW dbo.EmailActivity
AS
SELECT ID, EmailCampaignID, FanID, DeliveryDate, OpenDate, ClickDate, UnsubscribeDate, HardBounceDate, SoftBounceDate
FROM SLC_Snapshot.dbo.EmailActivity
GO
GRANT SELECT
    ON OBJECT::[dbo].[EmailActivity] TO [Analyst]
    AS [dbo];

