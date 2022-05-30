CREATE TABLE [Processing].[Masking_MIDTransactionCount] (
    [DateType]  VARCHAR (4)  NULL,
    [DateStart] DATE         NULL,
    [DateEnd]   DATE         NULL,
    [MID]       VARCHAR (50) NULL,
    [TranCount] INT          NULL,
    [isGB]      BIT          NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_aff_masking_midtransactioncount]
    ON [Processing].[Masking_MIDTransactionCount]([MID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated Staging table table that holds the Transaction Counts for each MID in ConsumerCombinations, split by GB and Non-GB status', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_MIDTransactionCount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A string that can be used to identify the date aggregation that is to be performed', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_MIDTransactionCount', @level2type = N'COLUMN', @level2name = N'DateType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The start date of the aggregation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_MIDTransactionCount', @level2type = N'COLUMN', @level2name = N'DateStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The end date of the aggregation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_MIDTransactionCount', @level2type = N'COLUMN', @level2name = N'DateEnd';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MID as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_MIDTransactionCount', @level2type = N'COLUMN', @level2name = N'MID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The count of transactions that occurred', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_MIDTransactionCount', @level2type = N'COLUMN', @level2name = N'TranCount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifies whether a ConsumerCombination is a GB combination or not', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_MIDTransactionCount', @level2type = N'COLUMN', @level2name = N'isGB';

