CREATE TABLE [InsightArchive].[PropensityTargetSpend] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [FanID]     INT          NOT NULL,
    [MonthDate] VARCHAR (10) NOT NULL,
    [Spend]     MONEY        NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

