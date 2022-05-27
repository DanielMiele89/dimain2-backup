CREATE TABLE [InsightArchive].[RedemptionIncome] (
    [ID]            TINYINT IDENTITY (1, 1) NOT NULL,
    [PartnerID]     INT     NOT NULL,
    [TradeUp_Value] MONEY   NOT NULL,
    [CashbackUsed]  MONEY   NOT NULL,
    [RewardIncome]  MONEY   NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

