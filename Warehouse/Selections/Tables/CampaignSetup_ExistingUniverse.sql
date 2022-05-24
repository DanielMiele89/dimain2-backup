CREATE TABLE [Selections].[CampaignSetup_ExistingUniverse] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID] INT      NULL,
    [StartDate]   DATETIME NULL,
    [CompositeID] BIGINT   NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_OfferStartComp]
    ON [Selections].[CampaignSetup_ExistingUniverse]([IronOfferID] ASC, [StartDate] ASC, [CompositeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Selections].[CampaignSetup_ExistingUniverse]([IronOfferID], [StartDate], [CompositeID])
    ON [Warehouse_Columnstores];

