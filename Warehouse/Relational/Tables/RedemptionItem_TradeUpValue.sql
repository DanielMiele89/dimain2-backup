CREATE TABLE [Relational].[RedemptionItem_TradeUpValue] (
    [RedeemID]                 INT        NOT NULL,
    [TradeUp_ClubCashRequired] SMALLMONEY NULL,
    [TradeUp_Value]            SMALLMONEY NULL,
    [PartnerID]                INT        NULL,
    PRIMARY KEY CLUSTERED ([RedeemID] ASC)
);

