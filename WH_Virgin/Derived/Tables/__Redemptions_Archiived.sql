CREATE TABLE [Derived].[__Redemptions_Archiived] (
    [FanID]                 INT             NOT NULL,
    [CompositeID]           BIGINT          NULL,
    [TranID]                INT             NOT NULL,
    [RedeemDate]            DATETIME        NOT NULL,
    [RedeemType]            VARCHAR (8)     NULL,
    [RedemptionDescription] NVARCHAR (4000) NULL,
    [PartnerID]             INT             NULL,
    [PartnerName]           VARCHAR (100)   NULL,
    [CashbackUsed]          SMALLMONEY      NOT NULL,
    [TradeUp_WithValue]     INT             NOT NULL,
    [TradeUp_Value]         SMALLMONEY      NULL,
    [Cancelled]             INT             NOT NULL,
    [GiftAid]               BIT             NOT NULL,
    CONSTRAINT [pk_TranID] PRIMARY KEY CLUSTERED ([TranID] ASC)
);

