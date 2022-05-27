CREATE TABLE [Report].[OfferReport_MatchTrans] (
    [DataSource] VARCHAR (15) NOT NULL,
    [RetailerID] INT          NOT NULL,
    [PartnerID]  INT          NOT NULL,
    [MID]        VARCHAR (50) NOT NULL,
    [FanID]      INT          NOT NULL,
    [CINID]      INT          NULL,
    [IsOnline]   BIT          NULL,
    [Amount]     SMALLMONEY   NOT NULL,
    [TranDate]   DATETIME     NOT NULL,
    [MatchID]    INT          NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_MatchID]
    ON [Report].[OfferReport_MatchTrans]([MatchID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_FanID]
    ON [Report].[OfferReport_MatchTrans]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerIDTrandDateAmount]
    ON [Report].[OfferReport_MatchTrans]([PartnerID] ASC, [TranDate] ASC, [Amount] ASC)
    INCLUDE([IsOnline]);


GO
CREATE NONCLUSTERED INDEX [IX_Amount_IncPartnerFanChannelDateID]
    ON [Report].[OfferReport_MatchTrans]([Amount] ASC)
    INCLUDE([PartnerID], [FanID], [IsOnline], [TranDate], [MatchID]);

