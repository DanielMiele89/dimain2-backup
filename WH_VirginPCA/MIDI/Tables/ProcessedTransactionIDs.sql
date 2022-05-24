CREATE TABLE [MIDI].[ProcessedTransactionIDs] (
    [TransactionID] VARCHAR (100)  NULL,
    [LoadDate]      DATETIME2 (7)  NULL,
    [FileName]      NVARCHAR (500) NULL
);


GO
CREATE CLUSTERED INDEX [CIX_TranID]
    ON [MIDI].[ProcessedTransactionIDs]([TransactionID] ASC) WITH (FILLFACTOR = 50);

