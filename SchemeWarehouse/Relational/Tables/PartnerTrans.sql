CREATE TABLE [Relational].[PartnerTrans] (
    [PartnerTransID]    INT        IDENTITY (1, 1) NOT NULL,
    [MatchID]           INT        NULL,
    [FanID]             INT        NOT NULL,
    [PartnerID]         INT        NULL,
    [OutletID]          INT        NULL,
    [TransactionAmount] SMALLMONEY NOT NULL,
    [TransactionDate]   DATE       NULL,
    [AddedDate]         DATE       NULL,
    [CashbackEarned]    MONEY      NULL,
    PRIMARY KEY CLUSTERED ([PartnerTransID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerTrans_PartnerID]
    ON [Relational].[PartnerTrans]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerTrans_FanID]
    ON [Relational].[PartnerTrans]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerTrans_TransactionDate]
    ON [Relational].[PartnerTrans]([TransactionDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerTrans_AddedDate]
    ON [Relational].[PartnerTrans]([AddedDate] ASC);

