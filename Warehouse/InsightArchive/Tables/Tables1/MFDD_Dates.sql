CREATE TABLE [InsightArchive].[MFDD_Dates] (
    [ID]                  INT    NOT NULL,
    [CycleStart]          DATE   NULL,
    [CycleEnd]            DATE   NULL,
    [Seasonality_CycleID] INT    NULL,
    [FirstDD_PeriodEnd]   DATE   NULL,
    [SecondDD_PeriodEnd]  DATE   NULL,
    [Exclusion]           INT    NOT NULL,
    [DateRow]             BIGINT NULL
);

