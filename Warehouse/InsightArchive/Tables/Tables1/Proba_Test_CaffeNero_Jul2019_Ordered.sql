CREATE TABLE [InsightArchive].[Proba_Test_CaffeNero_Jul2019_Ordered] (
    [ProbID]           INT        IDENTITY (1, 1) NOT NULL,
    [FanID]            INT        NOT NULL,
    [ModelProbability] FLOAT (53) NOT NULL,
    [Spender]          INT        NOT NULL,
    PRIMARY KEY CLUSTERED ([ProbID] ASC)
);

