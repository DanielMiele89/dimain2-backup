CREATE TABLE [Report].[OfferReport_AllTrans] (
    [DataSource]    VARCHAR (15) NOT NULL,
    [RetailerID]    INT          NOT NULL,
    [PartnerID]     INT          NOT NULL,
    [MID]           VARCHAR (50) NOT NULL,
    [FanID]         INT          NOT NULL,
    [CINID]         INT          NULL,
    [IsOnline]      BIT          NULL,
    [Amount]        SMALLMONEY   NOT NULL,
    [TranDate]      DATETIME     NOT NULL,
    [TransactionID] INT          NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_TransactionID]
    ON [Report].[OfferReport_AllTrans]([TransactionID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_FanID]
    ON [Report].[OfferReport_AllTrans]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerIDTrandDateAmount]
    ON [Report].[OfferReport_AllTrans]([PartnerID] ASC, [TranDate] ASC, [Amount] ASC)
    INCLUDE([IsOnline]);

