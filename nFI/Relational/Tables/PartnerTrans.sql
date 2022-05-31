CREATE TABLE [Relational].[PartnerTrans] (
    [ID]                  INT        IDENTITY (1, 1) NOT NULL,
    [MatchID]             INT        NULL,
    [FanID]               INT        NOT NULL,
    [PartnerID]           SMALLINT   NULL,
    [OutletID]            INT        NULL,
    [TransactionAmount]   SMALLMONEY NOT NULL,
    [TransactionDate]     DATETIME   NULL,
    [AddedDate]           DATE       NULL,
    [CashbackEarned]      SMALLMONEY NULL,
    [CommissionChargable] SMALLMONEY NULL,
    [IronOfferID]         INT        NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FID]
    ON [Relational].[PartnerTrans]([FanID] ASC)
    ON [nFI_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_PID]
    ON [Relational].[PartnerTrans]([PartnerID] ASC)
    ON [nFI_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_IID]
    ON [Relational].[PartnerTrans]([IronOfferID] ASC)
    ON [nFI_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_OID]
    ON [Relational].[PartnerTrans]([OutletID] ASC)
    ON [nFI_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_MID]
    ON [Relational].[PartnerTrans]([MatchID] ASC)
    ON [nFI_Indexes];


GO
DENY ALTER
    ON OBJECT::[Relational].[PartnerTrans] TO [OnCall]
    AS [dbo];


GO
DENY DELETE
    ON OBJECT::[Relational].[PartnerTrans] TO [OnCall]
    AS [dbo];

