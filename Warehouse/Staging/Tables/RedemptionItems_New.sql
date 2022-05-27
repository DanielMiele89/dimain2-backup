CREATE TABLE [Staging].[RedemptionItems_New] (
    [RedeemID]              INT             NOT NULL,
    [RedemptionDescription] NVARCHAR (4000) NULL,
    [RedeemType]            VARCHAR (8)     NULL,
    [Partnerid]             INT             NULL,
    [partnerName]           VARCHAR (100)   NULL,
    [CashbackUsed]          SMALLMONEY      NULL,
    [TradeUp_Value]         SMALLMONEY      NULL,
    [TradeUp_WithValue]     INT             NOT NULL
);

