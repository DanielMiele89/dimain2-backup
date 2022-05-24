CREATE TABLE [ExcelQuery].[MVP_DateTable] (
    [ID]                    INT  NOT NULL,
    [CycleStart]            DATE NULL,
    [CycleEnd]              DATE NULL,
    [Seasonality_CycleID]   INT  NULL,
    [FlaggedDate]           BIT  NULL,
    [EngagementFlaggedDate] BIT  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

