CREATE VIEW [dbo].ExtendedDataSets
AS
SELECT
    ID, LinkID, [Name], ItemID
FROM DataSets
UNION ALL
SELECT
    ID, LinkID, [Name], ItemID
FROM [ReportServerTempDB].dbo.TempDataSets
GO
GRANT SELECT
    ON OBJECT::[dbo].[ExtendedDataSets] TO [RSExecRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[dbo].[ExtendedDataSets] TO [RSExecRole]
    AS [dbo];

