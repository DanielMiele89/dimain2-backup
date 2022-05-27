CREATE TABLE [dbo].[ProcessBoundaryValues] (
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
    [ProcessName]  VARCHAR (100)  NOT NULL,
    [Action]       VARCHAR (100)  NOT NULL,
    [Description]  VARCHAR (8000) NOT NULL,
    [TableName]    VARCHAR (100)  NULL,
    [LastUsedDate] DATETIME       NULL,
    [LastUsedKey]  BIGINT         NULL
);

