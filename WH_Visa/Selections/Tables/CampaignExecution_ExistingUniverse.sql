CREATE TABLE [Selections].[CampaignExecution_ExistingUniverse] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID] INT      NULL,
    [StartDate]   DATETIME NULL,
    [CompositeID] BIGINT   NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Selections].[CampaignExecution_ExistingUniverse]([IronOfferID], [StartDate], [CompositeID]);

