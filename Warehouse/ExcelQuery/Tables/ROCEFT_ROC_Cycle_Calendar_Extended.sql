CREATE TABLE [ExcelQuery].[ROCEFT_ROC_Cycle_Calendar_Extended] (
    [ID]                  INT  IDENTITY (1, 1) NOT NULL,
    [CycleStart]          DATE NULL,
    [CycleEnd]            DATE NULL,
    [Seasonality_CycleID] INT  NULL,
    CONSTRAINT [PK_ROCEFT_ROC_Cycle_Calendar_Extended] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UC_ROCEFT_ROC_Cycle_Calendar_Extended] UNIQUE NONCLUSTERED ([CycleStart] ASC, [CycleEnd] ASC)
);

