CREATE VIEW [dbo].IssuerCustomer
AS
SELECT ID, IssuerID, SourceUID, [Date]
FROM SLC_Snapshot.dbo.IssuerCustomer
GO
GRANT SELECT
    ON OBJECT::[dbo].[IssuerCustomer] TO [Analyst]
    AS [dbo];

