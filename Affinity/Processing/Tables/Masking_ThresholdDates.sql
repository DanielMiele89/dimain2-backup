CREATE TABLE [Processing].[Masking_ThresholdDates] (
    [ID]                 INT          IDENTITY (1, 1) NOT NULL,
    [DateType]           VARCHAR (10) NULL,
    [ThresholdDateStart] DATE         NULL,
    [ThresholdDateEnd]   DATE         NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated Staging table that holds the set of dates that should be considered for counting MID Transactions for Processing.Masking_MIDTransactionCount', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ThresholdDates';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'IDENTITY column -- used for looping', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ThresholdDates', @level2type = N'COLUMN', @level2name = N'ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A string that identifies the type of date aggregation that was performed', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ThresholdDates', @level2type = N'COLUMN', @level2name = N'DateType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date that represents the start of the range to count transactions for mids', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ThresholdDates', @level2type = N'COLUMN', @level2name = N'ThresholdDateStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date that represents the end of the range to count transactions for mids', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ThresholdDates', @level2type = N'COLUMN', @level2name = N'ThresholdDateEnd';

