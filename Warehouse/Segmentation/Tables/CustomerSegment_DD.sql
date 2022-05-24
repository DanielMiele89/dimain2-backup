CREATE TABLE [Segmentation].[CustomerSegment_DD] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [FanID]                INT      NOT NULL,
    [PartnerID]            INT      NOT NULL,
    [ShopperSegmentTypeID] SMALLINT NOT NULL,
    [StartDate]            DATE     NOT NULL,
    [EndDate]              DATE     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ID_PartnerEndDate]
    ON [Segmentation].[CustomerSegment_DD]([PartnerID] ASC, [EndDate] ASC)
    INCLUDE([ID], [FanID], [ShopperSegmentTypeID]) WITH (FILLFACTOR = 70);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerFan]
    ON [Segmentation].[CustomerSegment_DD]([PartnerID] ASC, [FanID] ASC)
    INCLUDE([ShopperSegmentTypeID], [StartDate], [EndDate]) WITH (FILLFACTOR = 70);

