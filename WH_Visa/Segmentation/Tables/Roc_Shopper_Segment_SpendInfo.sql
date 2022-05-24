CREATE TABLE [Segmentation].[Roc_Shopper_Segment_SpendInfo] (
    [FanID]     INT      NOT NULL,
    [PartnerID] INT      NOT NULL,
    [Spend]     MONEY    NULL,
    [Segment]   SMALLINT NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

