CREATE TABLE [Inbound].[OfferDetail] (
    [ID]                 BIGINT           IDENTITY (1, 1) NOT NULL,
    [OfferDetailGUID]    UNIQUEIDENTIFIER NOT NULL,
    [OfferGUID]          UNIQUEIDENTIFIER NULL,
    [OfferCap]           MONEY            NULL,
    [IsBounty]           BIT              NULL,
    [Override]           DECIMAL (8, 4)   NULL,
    [BillingRate]        DECIMAL (8, 4)   NULL,
    [MarketingRate]      DECIMAL (8, 4)   NULL,
    [MinimumSpendAmount] INT              NULL,
    [MaximumSpendAmount] INT              NULL,
    [LoadDate]           DATETIME2 (7)    NOT NULL,
    [FileName]           NVARCHAR (320)   NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

