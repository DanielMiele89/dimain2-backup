CREATE TABLE [InsightArchive].[ProbaOrder] (
    [ProbOrderID]      INT        IDENTITY (1, 1) NOT NULL,
    [TargetSpender]    INT        NOT NULL,
    [ModelProbability] FLOAT (53) NOT NULL,
    PRIMARY KEY CLUSTERED ([ProbOrderID] ASC)
);

