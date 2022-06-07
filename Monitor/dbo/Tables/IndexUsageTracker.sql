CREATE TABLE [dbo].[IndexUsageTracker] (
    [DateCollected] DATETIME  NULL,
    [SchemaName]    [sysname] NOT NULL,
    [TableName]     [sysname] NOT NULL,
    [IndexName]     [sysname] NOT NULL,
    [TotalUsage]    INT       NULL,
    [LastAccess]    DATETIME  NULL
);

