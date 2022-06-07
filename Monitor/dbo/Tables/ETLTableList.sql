CREATE TABLE [dbo].[ETLTableList] (
    [ID]          INT       NULL,
    [TableName]   [sysname] NOT NULL,
    [SchemaName]  [sysname] NOT NULL,
    [DeltaOrFull] CHAR (1)  NULL
);

