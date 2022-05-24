CREATE TABLE [ExcelQuery].[Dates] (
    [ID]                  INT  NOT NULL,
    [CycleStart]          DATE NULL,
    [CycleEnd]            DATE NULL,
    [Seasonality_CycleID] INT  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

