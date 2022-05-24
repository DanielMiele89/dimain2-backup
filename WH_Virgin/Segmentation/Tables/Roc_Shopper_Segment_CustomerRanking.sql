CREATE TABLE [Segmentation].[Roc_Shopper_Segment_CustomerRanking] (
    [FanID]     INT NOT NULL,
    [PartnerID] INT NOT NULL,
    [Ranking]   INT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC, [PartnerID] ASC) WITH (FILLFACTOR = 100)
);

