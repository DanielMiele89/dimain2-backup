CREATE TABLE [Selections].[ImportedRows_20191203] (
    [IronOfferID] INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [ImportDate]  DATETIME NOT NULL,
    [IsControl]   BIT      NOT NULL
);


GO
CREATE CLUSTERED INDEX [ucx_Stuff]
    ON [Selections].[ImportedRows_20191203]([IronOfferID] ASC, [CompositeID] ASC, [StartDate] ASC) WITH (DATA_COMPRESSION = PAGE);


GO
CREATE COLUMNSTORE INDEX [CSI_All]
    ON [Selections].[ImportedRows_20191203]([IronOfferID], [StartDate], [EndDate], [CompositeID])
    ON [Warehouse_Columnstores];

