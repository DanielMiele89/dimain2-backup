CREATE TABLE [MI].[ReportPortalUseAnalysis] (
    [ID]       INT          NOT NULL,
    [RunDate]  DATE         NOT NULL,
    [UserName] VARCHAR (50) NOT NULL,
    [Report]   VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_MI_ReportPortalUseAnalysis] PRIMARY KEY CLUSTERED ([ID] ASC)
);

