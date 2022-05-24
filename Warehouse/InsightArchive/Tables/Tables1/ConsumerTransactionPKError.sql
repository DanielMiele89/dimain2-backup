CREATE TABLE [InsightArchive].[ConsumerTransactionPKError] (
    [FileID] INT NOT NULL,
    [RowNum] INT NOT NULL,
    CONSTRAINT [PK_IA_ConsumerTransactionPKError] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

