CREATE TABLE [Derived].[__SchemeTrans_Archived] (
    [ID]                  INT        NOT NULL,
    [Spend]               MONEY      NOT NULL,
    [RetailerCashback]    MONEY      NOT NULL,
    [TranDate]            DATE       NOT NULL,
    [AddedDate]           DATE       NOT NULL,
    [FanID]               INT        NOT NULL,
    [RetailerID]          INT        NOT NULL,
    [PublisherID]         INT        NOT NULL,
    [PublisherCommission] MONEY      NOT NULL,
    [RewardCommission]    SMALLMONEY NOT NULL,
    [TranFixDate]         DATE       NULL,
    [IsNegative]          BIT        CONSTRAINT [DF_BI_SchemeTrans_IsNegative] DEFAULT ((0)) NOT NULL,
    [Investment]          MONEY      NOT NULL,
    [IsOnline]            BIT        NOT NULL,
    [IsRetailMonthly]     BIT        CONSTRAINT [DF_BI_SchemeTrans_IsRetailMonthly] DEFAULT ((1)) NOT NULL,
    [NotRewardManaged]    BIT        NOT NULL,
    [SpendStretchAmount]  MONEY      NULL,
    [IsSpendStretch]      BIT        NULL,
    [IronOfferID]         INT        NULL,
    [OutletID]            INT        NOT NULL,
    [PanID]               INT        NULL,
    [SubPublisherID]      TINYINT    NOT NULL,
    [IsRetailerReport]    BIT        NOT NULL,
    [OfferPercentage]     FLOAT (53) NOT NULL,
    [CommissionRate]      FLOAT (53) NOT NULL,
    [VATCommission]       MONEY      NOT NULL,
    [GrossCommission]     MONEY      NOT NULL,
    [TranTime]            TIME (7)   NOT NULL,
    CONSTRAINT [PK_BI_SchemeTrans] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_stuff]
    ON [Derived].[__SchemeTrans_Archived]([PublisherID] ASC, [SubPublisherID] ASC, [IsRetailerReport] ASC, [TranDate] ASC)
    INCLUDE([Spend], [FanID], [RetailerID], [Investment]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [Derived].[__SchemeTrans_Archived]([IsRetailerReport] ASC, [TranDate] ASC, [RetailerID] ASC, [Investment] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_stuff2]
    ON [Derived].[__SchemeTrans_Archived]([NotRewardManaged] ASC, [RetailerID] ASC)
    INCLUDE([Spend], [RetailerCashback], [TranDate], [FanID], [PublisherID], [PublisherCommission], [RewardCommission], [Investment]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff3]
    ON [Derived].[__SchemeTrans_Archived]([IsRetailerReport] ASC, [RetailerID] ASC, [TranDate] ASC)
    INCLUDE([IronOfferID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_stuff5]
    ON [Derived].[__SchemeTrans_Archived]([NotRewardManaged] ASC, [RetailerID] ASC)
    INCLUDE([Spend], [TranDate], [PublisherID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff6]
    ON [Derived].[__SchemeTrans_Archived]([IsRetailerReport] ASC, [IronOfferID] ASC, [TranDate] ASC, [RetailerID] ASC, [Investment] ASC)
    INCLUDE([Spend], [FanID], [IsSpendStretch]) WITH (FILLFACTOR = 80);

