CREATE TABLE [dbo].[Earnings] (
    [EarningID]                 INT           IDENTITY (1, 1) NOT NULL,
    [ConsumerID]                INT           NOT NULL,
    [PartnerID]                 INT           NULL,
    [RetailerID]                INT           NULL,
    [OutletID]                  INT           NULL,
    [IsOnline]                  BIT           NULL,
    [CardHolderPresentData]     CHAR (1)      NULL,
    [TransactionAmount]         SMALLMONEY    NOT NULL,
    [ExtremeValueFlag]          BIT           NULL,
    [TransactionDate]           DATE          NULL,
    [AffiliateCommissionAmount] SMALLMONEY    NULL,
    [CommissionChargable]       MONEY         NULL,
    [CashbackEarned]            MONEY         NULL,
    [OfferID]                   INT           NULL,
    [ActivationDays]            INT           NULL,
    [AboveBase]                 INT           NULL,
    [PaymentMethodID]           TINYINT       NULL,
    [SourceID]                  VARCHAR (36)  NOT NULL,
    [SourceTypeID]              INT           NOT NULL,
    [SourceAddedDate]           DATE          NULL,
    [CreatedDateTime]           DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_Earnings] PRIMARY KEY CLUSTERED ([EarningID] ASC),
    CONSTRAINT [FK_Earnings_ConsumerID] FOREIGN KEY ([ConsumerID]) REFERENCES [dbo].[Consumer] ([ConsumerID]),
    CONSTRAINT [FK_Earnings_OfferID] FOREIGN KEY ([OfferID]) REFERENCES [dbo].[Offer] ([OfferID]),
    CONSTRAINT [FK_Earnings_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);


GO
CREATE NONCLUSTERED INDEX [NIX_ConsumerID]
    ON [dbo].[Earnings]([ConsumerID] ASC);


GO
ALTER INDEX [NIX_ConsumerID]
    ON [dbo].[Earnings] DISABLE;


GO
CREATE NONCLUSTERED INDEX [NIX_OfferID]
    ON [dbo].[Earnings]([OfferID] ASC);


GO
ALTER INDEX [NIX_OfferID]
    ON [dbo].[Earnings] DISABLE;


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_SourceType_SourceID]
    ON [dbo].[Earnings]([SourceTypeID] ASC, [SourceID] ASC);


GO
ALTER INDEX [UNIX_SourceType_SourceID]
    ON [dbo].[Earnings] DISABLE;

