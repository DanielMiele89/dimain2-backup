CREATE TABLE [InsightArchive].[ReportPortalUseAnalysis] (
    [ID]       INT          IDENTITY (1, 1) NOT NULL,
    [RunDate]  DATE         NOT NULL,
    [UserName] VARCHAR (50) NOT NULL,
    [Report]   VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

