CREATE TABLE [InsightArchive].[Proba_Test_Nov2019_retrain] (
    [FanID]            INT        NOT NULL,
    [ModelProbability] FLOAT (53) NOT NULL,
    [Spender]          INT        DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

