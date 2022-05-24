CREATE TABLE [Staging].[WeeklySummaryV2_RetailerAnalysisPeriods] (
    [RetailerID] INT          NOT NULL,
    [StartDate]  DATE         NOT NULL,
    [EndDate]    DATE         NOT NULL,
    [PeriodType] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_WeeklySummaryV2_RetailerAnalysisPeriods] PRIMARY KEY CLUSTERED ([RetailerID] ASC, [StartDate] ASC, [EndDate] ASC, [PeriodType] ASC)
);

