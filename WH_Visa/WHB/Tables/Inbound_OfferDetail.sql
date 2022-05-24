CREATE TABLE [WHB].[Inbound_OfferDetail] (
    [OfferDetailGUID]    UNIQUEIDENTIFIER NOT NULL,
    [OfferGUID]          UNIQUEIDENTIFIER NOT NULL,
    [OfferCap]           MONEY            NULL,
    [IsBounty]           BIT              NULL,
    [Override]           DECIMAL (8, 4)   NULL,
    [BillingRate]        DECIMAL (8, 4)   NULL,
    [MarketingRate]      DECIMAL (8, 4)   NULL,
    [MinimumSpendAmount] MONEY            NULL,
    [MaximumSpendAmount] MONEY            NULL,
    [LoadDate]           DATETIME2 (7)    NULL,
    [FileName]           NVARCHAR (100)   NULL
);

