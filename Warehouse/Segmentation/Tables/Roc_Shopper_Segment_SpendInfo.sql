CREATE TABLE [Segmentation].[Roc_Shopper_Segment_SpendInfo] (
    [FanID]     INT      NOT NULL,
    [PartnerID] INT      NOT NULL,
    [Spend]     MONEY    NULL,
    [Segment]   SMALLINT NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Roc_Shopper_Segment_SpendInfo_FanIDSegmentSpend]
    ON [Segmentation].[Roc_Shopper_Segment_SpendInfo]([FanID] ASC, [Segment] ASC, [Spend] ASC)
    INCLUDE([PartnerID]);


GO
CREATE NONCLUSTERED INDEX [i_Roc_Shopper_Segment_SpendInfo_PartnerIDSegment]
    ON [Segmentation].[Roc_Shopper_Segment_SpendInfo]([PartnerID] ASC, [Segment] ASC);

