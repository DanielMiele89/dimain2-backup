CREATE TABLE [Relational].[CampaignHistory_Archive] (
    [ironoffercyclesid] INT NOT NULL,
    [fanid]             INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ironoffercyclesid] ASC, [fanid] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE COLUMNSTORE INDEX [csx_Stuff]
    ON [Relational].[CampaignHistory_Archive]([fanid], [ironoffercyclesid])
    ON [Warehouse_Columnstores];

