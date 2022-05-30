CREATE TABLE [Processing].[Historical_Log] (
    [StartDate]         DATE     NOT NULL,
    [EndDate]           DATE     NOT NULL,
    [isCompleted]       BIT      DEFAULT ((0)) NOT NULL,
    [CompletedDateTime] DATETIME NULL,
    [RowsInFile]        INT      NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historical Log table, is only used for running historical perturbations', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Historical_Log';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The start date of the historical file to be generated', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Historical_Log', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The end date of the historical file to be generated', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Historical_Log', @level2type = N'COLUMN', @level2name = N'EndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifies whether a row in the historical table has been completed', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Historical_Log', @level2type = N'COLUMN', @level2name = N'isCompleted';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The DATETIME that the Historical file was genereated', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Historical_Log', @level2type = N'COLUMN', @level2name = N'CompletedDateTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The number of rows that were extracted into historical file', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Historical_Log', @level2type = N'COLUMN', @level2name = N'RowsInFile';

