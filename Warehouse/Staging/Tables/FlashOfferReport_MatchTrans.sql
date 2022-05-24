CREATE TABLE [Staging].[FlashOfferReport_MatchTrans] (
    [MatchID]        INT   NOT NULL,
    [AddedDate]      DATE  NOT NULL,
    [TranDate]       DATE  NOT NULL,
    [FanID]          INT   NOT NULL,
    [PartnerID]      INT   NOT NULL,
    [Spend]          MONEY NOT NULL,
    [StatusID]       INT   NOT NULL,
    [RewardStatusID] INT   NOT NULL,
    [IsOnline]       BIT   NOT NULL,
    [PanID]          INT   NULL,
    CONSTRAINT [PK_FlashOfferReport_MatchTrans] PRIMARY KEY CLUSTERED ([MatchID] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_FlashOfferReport_MatchTrans]
    ON [Staging].[FlashOfferReport_MatchTrans]([FanID] ASC, [TranDate] ASC, [PartnerID] ASC);

