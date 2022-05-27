CREATE TABLE [InsightArchive].[Proba_Test_Nov2019_Retrain_Ordered] (
    [ID]               INT        NOT NULL,
    [FanID]            INT        NOT NULL,
    [ModelProbability] FLOAT (53) NOT NULL,
    [Spender]          INT        NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

