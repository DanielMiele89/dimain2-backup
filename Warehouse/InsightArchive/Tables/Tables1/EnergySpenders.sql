CREATE TABLE [InsightArchive].[EnergySpenders] (
    [FanID]            INT  NOT NULL,
    [firstEnergySpend] DATE NULL,
    [firstDebitSpend]  DATE NULL,
    [firstCreditSpend] DATE NULL,
    [firstDDSpend]     DATE NULL,
    [CINID]            INT  NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

