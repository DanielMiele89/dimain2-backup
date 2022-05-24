CREATE TABLE [Segmentation].[Roc_Shopper_Segment_HeatmapInfo] (
    [FanID]     INT NOT NULL,
    [PartnerID] INT NOT NULL,
    [Index_RR]  INT NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Roc_Shopper_Segment_HeatmapInfo_IndexRRFanID]
    ON [Segmentation].[Roc_Shopper_Segment_HeatmapInfo]([Index_RR] ASC, [FanID] ASC);

