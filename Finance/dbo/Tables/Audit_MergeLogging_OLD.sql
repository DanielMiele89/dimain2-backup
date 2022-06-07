CREATE TABLE [dbo].[Audit_MergeLogging_OLD] (
    [RunID]          BIGINT        NULL,
    [RunDateTime]    DATETIME2 (7) NOT NULL,
    [StoredProcName] VARCHAR (100) NOT NULL,
    [InsertedRows]   INT           NULL,
    [UpdatedRows]    INT           NULL,
    [DeletedRows]    INT           NULL
);

