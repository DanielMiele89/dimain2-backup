CREATE TABLE [Segmentation].[ROC_Shopper_Segment_Members] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [FanID]                INT      NOT NULL,
    [PartnerID]            INT      NOT NULL,
    [ShopperSegmentTypeID] SMALLINT NOT NULL,
    [StartDate]            DATE     NOT NULL,
    [EndDate]              DATE     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [ix_PartnerID_EndDate]
    ON [Segmentation].[ROC_Shopper_Segment_Members]([PartnerID] ASC, [EndDate] ASC)
    INCLUDE([ID], [FanID], [ShopperSegmentTypeID]) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [nFI_Indexes];

