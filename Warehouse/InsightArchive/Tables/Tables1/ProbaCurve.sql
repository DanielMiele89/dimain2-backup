CREATE TABLE [InsightArchive].[ProbaCurve] (
    [RecallProbID] TINYINT    NOT NULL,
    [TruePercent]  FLOAT (53) NOT NULL,
    PRIMARY KEY CLUSTERED ([RecallProbID] ASC)
);

