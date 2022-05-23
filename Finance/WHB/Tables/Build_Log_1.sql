CREATE TABLE [WHB].[Build_Log] (
    [LogID]          INT           IDENTITY (1, 1) NOT NULL,
    [RunID]          INT           NULL,
    [StartDateTime]  DATETIME2 (7) NOT NULL,
    [EndDateTime]    DATETIME2 (7) NOT NULL,
    [StoredProcName] VARCHAR (100) NOT NULL,
    [InsertedRows]   BIGINT        NULL,
    [UpdatedRows]    INT           NULL,
    [DeletedRows]    INT           NULL,
    CONSTRAINT [PK_WHB_Build_Log] PRIMARY KEY CLUSTERED ([LogID] ASC) WITH (FILLFACTOR = 90)
);

