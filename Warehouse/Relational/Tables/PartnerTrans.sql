CREATE TABLE [Relational].[PartnerTrans] (
    [MatchID]                         INT        NOT NULL,
    [FanID]                           INT        NOT NULL,
    [PartnerID]                       INT        NULL,
    [OutletID]                        INT        NULL,
    [IsOnline]                        BIT        NULL,
    [CardHolderPresentData]           CHAR (1)   NULL,
    [TransactionAmount]               SMALLMONEY NOT NULL,
    [ExtremeValueFlag]                BIT        NULL,
    [TransactionDate]                 DATE       NULL,
    [TransactionWeekStarting]         DATE       NULL,
    [TransactionMonth]                TINYINT    NULL,
    [TransactionYear]                 SMALLINT   NULL,
    [TransactionWeekStartingCampaign] DATE       NULL,
    [AddedDate]                       DATE       NULL,
    [AddedWeekStarting]               DATE       NULL,
    [AddedMonth]                      TINYINT    NULL,
    [AddedYear]                       SMALLINT   NULL,
    [status]                          INT        NOT NULL,
    [rewardstatus]                    INT        NOT NULL,
    [AffiliateCommissionAmount]       SMALLMONEY NULL,
    [EligibleForCashBack]             BIT        NULL,
    [CommissionChargable]             MONEY      NULL,
    [CashbackEarned]                  MONEY      NULL,
    [IronOfferID]                     INT        NULL,
    [ActivationDays]                  INT        NULL,
    [AboveBase]                       INT        NULL,
    [PaymentMethodID]                 TINYINT    NULL,
    PRIMARY KEY CLUSTERED ([MatchID] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [i_FanID]
    ON [Relational].[PartnerTrans]([FanID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [i_TransactionWeekStarting]
    ON [Relational].[PartnerTrans]([TransactionWeekStarting] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [i_TranAssessment]
    ON [Relational].[PartnerTrans]([MatchID] ASC, [FanID] ASC, [PartnerID] ASC, [OutletID] ASC, [AddedDate] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_TransactionDate_PartnerID]
    ON [Relational].[PartnerTrans]([TransactionDate] ASC)
    INCLUDE([PartnerID], [MatchID], [OutletID]) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_Stuff01]
    ON [Relational].[PartnerTrans]([PartnerID] ASC)
    INCLUDE([MatchID], [FanID], [TransactionAmount], [AddedDate], [CashbackEarned], [AboveBase], [PaymentMethodID]) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_Stuff02]
    ON [Relational].[PartnerTrans]([FanID] ASC, [PartnerID] ASC, [TransactionDate] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_Stuff03]
    ON [Relational].[PartnerTrans]([MatchID] ASC, [PartnerID] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

