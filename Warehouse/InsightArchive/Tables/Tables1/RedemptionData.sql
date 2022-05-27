CREATE TABLE [InsightArchive].[RedemptionData] (
    [TranID]        INT          NOT NULL,
    [RedeemDate]    DATE         NULL,
    [RedeemType]    VARCHAR (50) NULL,
    [RedeemPartner] VARCHAR (50) NULL,
    [CashbackUsed]  MONEY        NOT NULL,
    [TradeUpValue]  MONEY        NOT NULL,
    [RewardIncome]  MONEY        NOT NULL,
    [Age]           SMALLINT     NULL,
    [CameoGroup]    VARCHAR (50) NULL,
    PRIMARY KEY CLUSTERED ([TranID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

