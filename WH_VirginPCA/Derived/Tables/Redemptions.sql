CREATE TABLE [Derived].[Redemptions] (
    [ID]                       INT              IDENTITY (1, 1) NOT NULL,
    [Currency]                 VARCHAR (3)      NULL,
    [RedemptionType]           VARCHAR (8)      NOT NULL,
    [RedemptionPartnerGUID]    UNIQUEIDENTIFIER NULL,
    [RedemptionOfferGUID]      UNIQUEIDENTIFIER NULL,
    [TransactionGUID]          UNIQUEIDENTIFIER NOT NULL,
    [TradeUp_RedemptionItemID] INT              NULL,
    [CustomerGUID]             UNIQUEIDENTIFIER NULL,
    [FanID]                    INT              NOT NULL,
    [CashbackUsed]             DECIMAL (16, 2)  NULL,
    [CashbackEarned]           DECIMAL (16, 2)  NULL,
    [RedeemedDate]             DATETIME2 (7)    NULL,
    [ConfirmedDate]            DATETIME2 (7)    NULL
);

