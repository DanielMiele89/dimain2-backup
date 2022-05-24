CREATE TABLE [Segmentation].[Roc_Shopper_Segment_Members] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [FanID]                INT      NOT NULL,
    [PartnerID]            INT      NOT NULL,
    [ShopperSegmentTypeID] SMALLINT NOT NULL,
    [StartDate]            DATE     NOT NULL,
    [EndDate]              DATE     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 70, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentEndDate_IncFanPartner]
    ON [Segmentation].[Roc_Shopper_Segment_Members]([ShopperSegmentTypeID] ASC, [EndDate] ASC)
    INCLUDE([FanID], [PartnerID]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_PartnerID_FanID]
    ON [Segmentation].[Roc_Shopper_Segment_Members]([PartnerID] ASC, [FanID] ASC)
    INCLUDE([ShopperSegmentTypeID], [StartDate], [EndDate]) WITH (FILLFACTOR = 70, DATA_COMPRESSION = ROW)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_PartnerID_EndDate]
    ON [Segmentation].[Roc_Shopper_Segment_Members]([PartnerID] ASC, [EndDate] ASC)
    INCLUDE([ID], [FanID], [ShopperSegmentTypeID]) WITH (FILLFACTOR = 70, DATA_COMPRESSION = ROW)
    ON [Warehouse_Indexes];

