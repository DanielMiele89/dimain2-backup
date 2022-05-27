CREATE TABLE [Segmentation].[CurrentCustomerSegment] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]            INT      NOT NULL,
    [FanID]                INT      NOT NULL,
    [ShopperSegmentTypeID] SMALLINT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerFanSegment]
    ON [Segmentation].[CurrentCustomerSegment]([PartnerID] ASC, [FanID] ASC, [ShopperSegmentTypeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Segmentation].[CurrentCustomerSegment]([PartnerID], [FanID], [ShopperSegmentTypeID])
    ON [Warehouse_Columnstores];

