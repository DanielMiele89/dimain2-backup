CREATE TABLE [Segmentation].[CurrentCustomerSegment] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]            INT      NOT NULL,
    [FanID]                INT      NOT NULL,
    [ShopperSegmentTypeID] SMALLINT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Segmentation].[CurrentCustomerSegment]([PartnerID], [FanID], [ShopperSegmentTypeID]);

