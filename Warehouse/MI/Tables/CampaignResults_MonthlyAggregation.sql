CREATE TABLE [MI].[CampaignResults_MonthlyAggregation] (
    [ID]                      INT           IDENTITY (1, 1) NOT NULL,
    [IronOfferID]             INT           NULL,
    [PublisherID]             INT           NULL,
    [PartnerID]               INT           NULL,
    [OfferName]               NVARCHAR (30) NULL,
    [ExposedCardholders]      INT           NULL,
    [ExposedTransactions]     INT           NULL,
    [ExposedSpend]            MONEY         NULL,
    [IncrementalSpenders]     REAL          NULL,
    [IncrementalTransactions] REAL          NULL,
    [IncrementalSales]        REAL          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_IronOffer]
    ON [MI].[CampaignResults_MonthlyAggregation]([IronOfferID] ASC);

