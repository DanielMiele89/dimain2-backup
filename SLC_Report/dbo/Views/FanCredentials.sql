

CREATE VIEW [dbo].[FanCredentials]
AS
SELECT ID, FanID, HashedPassword, OnlineRegistrationDate, HideFirstTimeSSOLogin, OnlineRegistrationSourceID
FROM SLC_Snapshot.dbo.FanCredentials
