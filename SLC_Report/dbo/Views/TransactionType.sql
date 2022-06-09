CREATE VIEW [dbo].TransactionType
AS
SELECT ID, Name, [Description], Multiplier
FROM SLC_Snapshot.dbo.TransactionType
GO
GRANT SELECT
    ON OBJECT::[dbo].[TransactionType] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[TransactionType] TO [Analyst]
    AS [dbo];

