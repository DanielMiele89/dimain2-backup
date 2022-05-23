CREATE TABLE [dbo].[PartitionInfo] (
    [object_id]              INT            NOT NULL,
    [SchemaName]             NVARCHAR (128) NULL,
    [TableName]              NVARCHAR (128) NULL,
    [PartitionSchemeName]    [sysname]      NOT NULL,
    [PartitionFilegroupName] [sysname]      NOT NULL,
    [PartitionFunctionName]  [sysname]      NOT NULL,
    [PartitionBoundaryValue] DATE           NULL,
    [PartitionKey]           [sysname]      NULL,
    [StartDate]              DATE           NOT NULL,
    [EndDate]                DATE           NOT NULL,
    [PartitionNumber]        INT            NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [dbo].[PartitionInfo]([object_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX]
    ON [dbo].[PartitionInfo]([StartDate] ASC, [EndDate] ASC)
    INCLUDE([PartitionNumber]) WITH (FILLFACTOR = 90);

