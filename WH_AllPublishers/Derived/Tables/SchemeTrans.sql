CREATE TABLE [Derived].[SchemeTrans] (
    [ID]                  INT          IDENTITY (1, 1) NOT NULL,
    [SourceID]            INT          NOT NULL,
    [SourceTableID]       INT          NOT NULL,
    [PublisherID]         INT          NOT NULL,
    [SubPublisherID]      TINYINT      NOT NULL,
    [NotRewardManaged]    BIT          NOT NULL,
    [RetailerID]          INT          NOT NULL,
    [PartnerID]           INT          NOT NULL,
    [OfferID]             INT          NULL,
    [IronOfferID]         INT          NULL,
    [OfferPercentage]     FLOAT (53)   NOT NULL,
    [CommissionRate]      FLOAT (53)   NOT NULL,
    [OutletID]            INT          NOT NULL,
    [FanID]               INT          NOT NULL,
    [PanID]               INT          NULL,
    [Spend]               MONEY        NOT NULL,
    [RetailerCashback]    MONEY        NOT NULL,
    [Investment]          MONEY        NOT NULL,
    [PublisherCommission] MONEY        NOT NULL,
    [RewardCommission]    SMALLMONEY   NOT NULL,
    [VATCommission]       MONEY        NOT NULL,
    [GrossCommission]     MONEY        NOT NULL,
    [TranDate]            DATE         NOT NULL,
    [TranFixDate]         DATE         NULL,
    [TranTime]            TIME (7)     NOT NULL,
    [IsNegative]          BIT          CONSTRAINT [DF_BI_SchemeTrans_New_IsNegative] DEFAULT ((0)) NOT NULL,
    [IsOnline]            BIT          NOT NULL,
    [IsSpendStretch]      BIT          NULL,
    [SpendStretchAmount]  MONEY        NULL,
    [IsRetailMonthly]     BIT          CONSTRAINT [DF_BI_SchemeTrans_New_IsRetailMonthly] DEFAULT ((1)) NOT NULL,
    [IsRetailerReport]    BIT          NOT NULL,
    [AddedDate]           DATE         NOT NULL,
    [MaskedCardNumber]    VARCHAR (19) NULL,
    CONSTRAINT [PK_BI_SchemeTrans_New] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_stuff]
    ON [Derived].[SchemeTrans]([PublisherID] ASC, [SubPublisherID] ASC, [IsRetailerReport] ASC, [TranDate] ASC)
    INCLUDE([Spend], [FanID], [RetailerID], [Investment]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [Derived].[SchemeTrans]([IsRetailerReport] ASC, [TranDate] ASC, [RetailerID] ASC, [Investment] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_stuff2]
    ON [Derived].[SchemeTrans]([NotRewardManaged] ASC, [RetailerID] ASC)
    INCLUDE([Spend], [RetailerCashback], [TranDate], [FanID], [PublisherID], [PublisherCommission], [RewardCommission], [Investment]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff3]
    ON [Derived].[SchemeTrans]([IsRetailerReport] ASC, [RetailerID] ASC, [TranDate] ASC)
    INCLUDE([IronOfferID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_stuff5]
    ON [Derived].[SchemeTrans]([NotRewardManaged] ASC, [RetailerID] ASC)
    INCLUDE([Spend], [TranDate], [PublisherID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff6]
    ON [Derived].[SchemeTrans]([IsRetailerReport] ASC, [IronOfferID] ASC, [TranDate] ASC, [RetailerID] ASC, [Investment] ASC)
    INCLUDE([Spend], [FanID], [IsSpendStretch]) WITH (FILLFACTOR = 80);

