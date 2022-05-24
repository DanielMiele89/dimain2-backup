CREATE TABLE [Derived].[RedemptionOffers] (
    [ID]                          INT              IDENTITY (1, 1) NOT NULL,
    [BankID]                      VARCHAR (250)    NULL,
    [RedemptionPartnerGUID]       UNIQUEIDENTIFIER NULL,
    [Currency]                    VARCHAR (3)      NULL,
    [RedemptionOfferGUID]         UNIQUEIDENTIFIER NULL,
    [RedemptionOfferID]           INT              NULL,
    [Charity_MinimumCashback]     DECIMAL (8, 4)   NULL,
    [TradeUp_CashbackRequired]    DECIMAL (8, 4)   NULL,
    [TradeUp_MarketingPercentage] DECIMAL (8, 4)   NULL,
    [TradeUp_WarningThreshold]    INT              NULL,
    [Status]                      VARCHAR (50)     NULL,
    [Priority]                    INT              NOT NULL
);

