CREATE TABLE [WHB].[Inbound_RedemptionOffers] (
    [BankID]                      VARCHAR (250)    NULL,
    [OfferType]                   VARCHAR (10)     NOT NULL,
    [RedemptionPartnerGUID]       UNIQUEIDENTIFIER NULL,
    [RedemptionPartnerName]       VARCHAR (250)    NULL,
    [Currency]                    VARCHAR (3)      NULL,
    [RedemptionOfferGUID]         UNIQUEIDENTIFIER NULL,
    [RedemptionOfferID]           INT              NULL,
    [Charity_MinimumCashback]     DECIMAL (16, 2)  NULL,
    [TradeUp_CashbackRequired]    DECIMAL (16, 2)  NULL,
    [TradeUp_MarketingPercentage] DECIMAL (16, 4)  NULL,
    [TradeUp_WarningThreshold]    INT              NULL,
    [Status]                      VARCHAR (50)     NULL,
    [Priority]                    INT              NOT NULL,
    [CreatedAt]                   DATETIME2 (7)    NULL,
    [UpdatedAt]                   DATETIME2 (7)    NULL,
    [LoadDate]                    DATETIME2 (7)    NULL,
    [FileName]                    NVARCHAR (100)   NULL
);

