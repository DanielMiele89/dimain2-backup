CREATE TABLE [InsightArchive].[TableRowCount] (
    [ID]            INT           IDENTITY (1, 1) NOT NULL,
    [DatabaseName]  VARCHAR (50)  NOT NULL,
    [SchemaName]    VARCHAR (50)  NOT NULL,
    [TableName]     VARCHAR (200) NOT NULL,
    [TableRowCount] BIGINT        NOT NULL,
    [MonitorDate]   DATE          CONSTRAINT [DF_InsightArchive_TableRowCount] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_InsightArchive_TableRowCount] PRIMARY KEY CLUSTERED ([ID] ASC)
);

