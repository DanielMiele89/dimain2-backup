CREATE TABLE [Segmentation].[Roc_Shopper_Segment_SpendInfo] (
    [FanID]     INT      NOT NULL,
    [PartnerID] INT      NOT NULL,
    [ClubID]    INT      NOT NULL,
    [Spend]     MONEY    NULL,
    [Segment]   SMALLINT NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_SpendInfo_FanID]
    ON [Segmentation].[Roc_Shopper_Segment_SpendInfo]([ClubID] ASC, [Spend] ASC, [Segment] ASC)
    INCLUDE([FanID]);


GO
CREATE NONCLUSTERED INDEX [idx_SpendInfo_ClubID]
    ON [Segmentation].[Roc_Shopper_Segment_SpendInfo]([PartnerID] ASC, [Segment] ASC)
    INCLUDE([FanID], [ClubID]);

