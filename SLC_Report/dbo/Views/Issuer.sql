CREATE VIEW [dbo].Issuer
AS
SELECT ID, Name, [Date]
FROM SLC_Snapshot.dbo.Issuer
GO
GRANT SELECT
    ON OBJECT::[dbo].[Issuer] TO [Analyst]
    AS [dbo];

