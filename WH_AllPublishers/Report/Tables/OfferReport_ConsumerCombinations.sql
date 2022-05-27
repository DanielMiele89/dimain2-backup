CREATE TABLE [Report].[OfferReport_ConsumerCombinations] (
    [DataSource]            VARCHAR (15) NULL,
    [RetailerID]            INT          NULL,
    [PartnerID]             INT          NULL,
    [MID]                   VARCHAR (50) NULL,
    [ConsumerCombinationID] INT          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UCX_SourceRetailerCC]
    ON [Report].[OfferReport_ConsumerCombinations]([DataSource] ASC, [RetailerID] ASC, [ConsumerCombinationID] ASC) WITH (FILLFACTOR = 80, STATISTICS_NORECOMPUTE = ON, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_RetailerID]
    ON [Report].[OfferReport_ConsumerCombinations]([RetailerID] ASC);

