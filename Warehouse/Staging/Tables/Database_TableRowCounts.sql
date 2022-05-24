CREATE TABLE [Staging].[Database_TableRowCounts] (
    [DatabaseName] VARCHAR (100) NOT NULL,
    [SchemaName]   VARCHAR (50)  NOT NULL,
    [TableName]    VARCHAR (100) NOT NULL,
    [RowCount]     INT           NOT NULL,
    [Date]         DATE          NOT NULL
);

