CREATE TABLE [Staging].[OfferReport_ConsumerCombinations] (
    [ConsumerCombinationID] INT NULL,
    [PartnerID]             INT NULL,
    [PublisherID]           INT NULL,
    [IsWarehouse]           BIT NULL,
    [IsVirgin]              BIT NULL,
    [IsVirginPCA]           BIT NULL,
    [IsVisaBarclaycard]     BIT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_CC]
    ON [Staging].[OfferReport_ConsumerCombinations]([PartnerID] ASC, [PublisherID] ASC, [IsWarehouse] ASC, [IsVirgin] ASC, [IsVirginPCA] ASC, [IsVisaBarclaycard] ASC, [ConsumerCombinationID] ASC) WITH (FILLFACTOR = 80, STATISTICS_NORECOMPUTE = ON);


GO
CREATE NONCLUSTERED INDEX [ix_PartnerID]
    ON [Staging].[OfferReport_ConsumerCombinations]([PartnerID] ASC) WITH (FILLFACTOR = 90);

