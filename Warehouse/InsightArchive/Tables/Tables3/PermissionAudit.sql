CREATE TABLE [InsightArchive].[PermissionAudit] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [DBName]         VARCHAR (100) NOT NULL,
    [ObjectType]     VARCHAR (100) NOT NULL,
    [SchemaName]     VARCHAR (100) NOT NULL,
    [ObjectName]     VARCHAR (100) NOT NULL,
    [PermissionName] VARCHAR (100) NOT NULL,
    [DBUserName]     VARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT INSERT
    ON OBJECT::[InsightArchive].[PermissionAudit] TO [peter]
    AS [dbo];

