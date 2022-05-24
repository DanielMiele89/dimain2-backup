CREATE TABLE [InsightArchive].[CurveCohort] (
    [CINID]          INT  NOT NULL,
    [FirstTranDate]  DATE NOT NULL,
    [FirstTranMonth] DATE NULL,
    PRIMARY KEY CLUSTERED ([CINID] ASC)
);

