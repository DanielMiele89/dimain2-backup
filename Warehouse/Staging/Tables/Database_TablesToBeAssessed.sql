CREATE TABLE [Staging].[Database_TablesToBeAssessed] (
    [DatabaseName] VARCHAR (100) NOT NULL,
    [SchemaName]   VARCHAR (50)  NOT NULL,
    [TableName]    VARCHAR (100) NOT NULL,
    [TableID]      INT           IDENTITY (1, 1) NOT NULL,
    [ToBeAssessed] BIT           NOT NULL,
    CONSTRAINT [PK_Database_TablesToBeAssessed] PRIMARY KEY CLUSTERED ([TableID] ASC)
);

