CREATE TABLE [DDLMonitor].[DDLSchemasToMonitor] (
    [ID]          TINYINT        IDENTITY (1, 1) NOT NULL,
    [SchemaName]  NVARCHAR (255) NOT NULL,
    [PrefixMatch] NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

