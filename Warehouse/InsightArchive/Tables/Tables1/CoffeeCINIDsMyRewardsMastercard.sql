CREATE TABLE [InsightArchive].[CoffeeCINIDsMyRewardsMastercard] (
    [CINID]             INT   NOT NULL,
    [StarbucksSpend]    MONEY NULL,
    [StarbucksVisits]   INT   NULL,
    [CaffeNeroSpend]    MONEY NULL,
    [CaffeNeroVisits]   INT   NULL,
    [PretAMangerSpend]  MONEY NULL,
    [PretAMangerVisits] INT   NULL,
    [CostaSpend]        MONEY NULL,
    [CostaVisits]       INT   NULL,
    PRIMARY KEY CLUSTERED ([CINID] ASC)
);

