CREATE TABLE [InsightArchive].[EATSpendVisitMyRewards] (
    [CINID]      INT        NOT NULL,
    [Spend]      MONEY      NOT NULL,
    [VisitCount] FLOAT (53) NOT NULL,
    PRIMARY KEY CLUSTERED ([CINID] ASC)
);

