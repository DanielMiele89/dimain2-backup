CREATE TABLE [Segmentation].[ConsumerTransactionsToSegment] (
    [PartnerID] INT  NOT NULL,
    [FanID]     INT  NOT NULL,
    [LastTran]  DATE NULL
);


GO
CREATE CLUSTERED INDEX [CIX_PartnerFanTran]
    ON [Segmentation].[ConsumerTransactionsToSegment]([PartnerID] ASC, [FanID] ASC, [LastTran] ASC) WITH (FILLFACTOR = 90);

