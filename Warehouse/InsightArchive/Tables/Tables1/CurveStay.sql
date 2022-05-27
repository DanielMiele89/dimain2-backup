CREATE TABLE [InsightArchive].[CurveStay] (
    [CINID]          INT  NOT NULL,
    [FirstTranDate]  DATE NOT NULL,
    [CountPeriodEnd] DATE NOT NULL,
    [StayCheckStart] DATE NOT NULL,
    [StayCheckEnd]   DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([CINID] ASC)
);

