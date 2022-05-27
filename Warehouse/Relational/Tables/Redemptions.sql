﻿CREATE TABLE [Relational].[Redemptions] (
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
    CONSTRAINT [pk_TranID] PRIMARY KEY CLUSTERED ([TranID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
);




GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[Redemptions]([FanID] ASC) WITH (FILLFACTOR = 80);


GO
DENY DELETE
    ON OBJECT::[Relational].[Redemptions] TO [OnCall]
    AS [dbo];


GO
DENY ALTER
    ON OBJECT::[Relational].[Redemptions] TO [OnCall]
    AS [dbo];

