CREATE TABLE [Segmentation].[Roc_Shopper_Segment_Members_Control] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [FanID]                INT      NOT NULL,
    [PartnerID]            INT      NOT NULL,
    [ShopperSegmentTypeID] SMALLINT NOT NULL,
    [StartDate]            DATE     NOT NULL,
    [EndDate]              DATE     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [I_Roc_Shopper_Segment_Members_Control_FanID]
    ON [Segmentation].[Roc_Shopper_Segment_Members_Control]([FanID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [I_Roc_Shopper_Segment_Members_Control_PartnerID]
    ON [Segmentation].[Roc_Shopper_Segment_Members_Control]([PartnerID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

