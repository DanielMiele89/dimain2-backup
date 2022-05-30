CREATE TABLE [Processing].[RowNum_Log] (
    [FileID] INT NOT NULL,
    [RowNum] INT NOT NULL,
    CONSTRAINT [pk_Processing_rownum_log] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Holds all the FileID/RowNum combinations that have been seen by the transaction pipeline for a period of time (for nFI Transactions, the FileID is set to -1 and the TransactionID is used as the RowNum).  Transactions are removed from this table periodically based on logic in Processing.LogTables_Maintain procedure.  ', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'RowNum_Log';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'FileID as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'RowNum_Log', @level2type = N'COLUMN', @level2name = N'FileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The RowNum as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'RowNum_Log', @level2type = N'COLUMN', @level2name = N'RowNum';

