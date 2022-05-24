CREATE TABLE [InsightArchive].[SegmentPOC_Customers] (
    [PK_ID]                      INT          IDENTITY (1, 1) NOT NULL,
    [CycleStart]                 DATE         NULL,
    [FanID]                      INT          NULL,
    [CINID]                      INT          NULL,
    [ActivateDate]               DATE         NULL,
    [DeactivatedDate]            DATE         NULL,
    [ComboID]                    INT          NULL,
    [MarketableByEmail]          BIT          NULL,
    [EngagementCat_LowFreq]      VARCHAR (30) NULL,
    [EngagementCat_HighFreq2080] VARCHAR (30) NULL,
    [EngagementCat_HighFreq5050] VARCHAR (30) NULL,
    PRIMARY KEY CLUSTERED ([PK_ID] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [InsightArchive].[SegmentPOC_Customers]([CycleStart] ASC, [CINID] ASC)
    INCLUDE([FanID], [MarketableByEmail], [EngagementCat_HighFreq2080], [EngagementCat_HighFreq5050], [EngagementCat_LowFreq]) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [nix_ComboID]
    ON [InsightArchive].[SegmentPOC_Customers]([ComboID] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [nix_CINID]
    ON [InsightArchive].[SegmentPOC_Customers]([CINID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [nix_CycleStartCINID]
    ON [InsightArchive].[SegmentPOC_Customers]([CycleStart] ASC)
    INCLUDE([CINID]) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [cix_CycleStart]
    ON [InsightArchive].[SegmentPOC_Customers]([CycleStart] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

