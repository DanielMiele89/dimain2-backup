CREATE TABLE [InsightArchive].[CoffeeAnalysis] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [TranMonthDate] DATE     NOT NULL,
    [BrandID]       SMALLINT NOT NULL,
    [CINID]         INT      NOT NULL,
    [Spend]         MONEY    NOT NULL,
    [TranCount]     INT      NOT NULL,
    [VisitDayCount] INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

