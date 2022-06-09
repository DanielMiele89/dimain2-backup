CREATE VIEW dbo.EmailEventCode
AS
SELECT ID, Name
FROM SLC_Snapshot.dbo.EmailEventCode
GO
GRANT SELECT
    ON OBJECT::[dbo].[EmailEventCode] TO [Analyst]
    AS [dbo];

