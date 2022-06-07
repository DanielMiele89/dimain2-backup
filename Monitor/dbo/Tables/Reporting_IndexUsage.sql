CREATE TABLE [dbo].[Reporting_IndexUsage] (
    [DBName]    VARCHAR (128) NOT NULL,
    [TableName] VARCHAR (128) NOT NULL,
    [IndexName] [sysname]     NOT NULL,
    [New]       INT           NULL,
    [Writes]    BIGINT        NOT NULL,
    [Reads]     BIGINT        NULL,
    [IndexType] NVARCHAR (60) NULL,
    [RunDate]   DATETIME      NOT NULL
);

