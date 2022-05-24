CREATE TABLE [Staging].[FixCT_MissingTransactionsToAdd_All] (
    [PartitionID] INT    NULL,
    [FileID]      INT    NULL,
    [RowNum]      BIGINT NULL,
    [CINID]       INT    NULL,
    [Amount]      MONEY  NULL,
    [TranDate]    DATE   NULL
);

