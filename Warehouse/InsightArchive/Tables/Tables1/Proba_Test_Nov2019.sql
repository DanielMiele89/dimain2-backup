CREATE TABLE [InsightArchive].[Proba_Test_Nov2019] (
    [ID]               INT        IDENTITY (1, 1) NOT NULL,
    [FanID]            INT        NOT NULL,
    [ModelProbability] FLOAT (53) NOT NULL,
    [NovSpender]       INT        DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

