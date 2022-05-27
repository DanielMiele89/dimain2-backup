CREATE TABLE [Segmentation].[Roc_Shopper_Segment_CustomerRanking] (
    [ID]        INT IDENTITY (1, 1) NOT NULL,
    [FanID]     INT NOT NULL,
    [PartnerID] INT NOT NULL,
    [Ranking]   INT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 100)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_PartnerID_FanID]
    ON [Segmentation].[Roc_Shopper_Segment_CustomerRanking]([PartnerID] ASC, [FanID] ASC)
    INCLUDE([Ranking]) WITH (FILLFACTOR = 90);


GO
ALTER INDEX [ix_PartnerID_FanID]
    ON [Segmentation].[Roc_Shopper_Segment_CustomerRanking] DISABLE;

