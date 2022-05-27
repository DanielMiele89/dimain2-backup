CREATE TABLE [Relational].[CampaignHistory] (
    [ironoffercyclesid] INT NOT NULL,
    [fanid]             INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ironoffercyclesid] ASC, [fanid] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IX_NCL_Relational_CampaignHistory_FanID_IronOfferCyclesID]
    ON [Relational].[CampaignHistory]([fanid] ASC, [ironoffercyclesid] ASC) WITH (FILLFACTOR = 95)
    ON [Warehouse_Indexes];


GO
ALTER INDEX [IX_NCL_Relational_CampaignHistory_FanID_IronOfferCyclesID]
    ON [Relational].[CampaignHistory] DISABLE;

