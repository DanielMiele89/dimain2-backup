CREATE TABLE [Staging].[JobLog_Temp] (
    [JobLogID]            INT           IDENTITY (1, 1) NOT NULL,
    [StoredProcedureName] VARCHAR (100) NOT NULL,
    [TableSchemaName]     VARCHAR (25)  NOT NULL,
    [TableName]           VARCHAR (100) NOT NULL,
    [StartDate]           DATETIME      NOT NULL,
    [EndDate]             DATETIME      NULL,
    [TableRowCount]       BIGINT        NULL,
    [AppendReload]        CHAR (1)      NULL,
    PRIMARY KEY CLUSTERED ([JobLogID] ASC)
);

