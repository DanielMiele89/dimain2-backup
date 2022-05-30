CREATE TABLE [dbo].[Masking_Results] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [Val]            INT           NOT NULL,
    [ResultType]     VARCHAR (100) NOT NULL,
    [ResultDateTime] DATETIME      NOT NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Holds a set of metrics from the Masking run that can be used for debugging and monitoring masking logic', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_Results';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'IDENTITY column', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_Results', @level2type = N'COLUMN', @level2name = N'ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The metric value', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_Results', @level2type = N'COLUMN', @level2name = N'Val';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Information about the metric that was calculated', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_Results', @level2type = N'COLUMN', @level2name = N'ResultType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The datetime that the results were inserted into table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_Results', @level2type = N'COLUMN', @level2name = N'ResultDateTime';

