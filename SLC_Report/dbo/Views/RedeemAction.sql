CREATE VIEW [dbo].RedeemAction
AS
SELECT ID, TransID, [Status], [Date]
FROM SLC_Snapshot.dbo.RedeemAction
GO
GRANT SELECT
    ON OBJECT::[dbo].[RedeemAction] TO [Analyst]
    AS [dbo];

