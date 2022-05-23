CREATE TABLE [Staging].[Transactions] (
    [StagingID]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerID]          INT            NULL,
    [OfferID]             INT            NULL,
    [EarningSourceID]     SMALLINT       NULL,
    [PublisherID]         SMALLINT       NULL,
    [PaymentCardID]       INT            NULL,
    [Spend]               DECIMAL (9, 2) NULL,
    [Earning]             DECIMAL (9, 2) NULL,
    [CurrencyCode]        CHAR (3)       NULL,
    [TranDate]            DATE           NULL,
    [TranDateTime]        DATETIME2 (7)  NULL,
    [PaymentMethodID]     SMALLINT       NULL,
    [ActivationDays]      INT            NULL,
    [EligibleDate]        DATE           NULL,
    [SourceTypeID]        SMALLINT       NULL,
    [SourceID]            VARCHAR (36)   NULL,
    [CreatedDateTime]     DATETIME2 (7)  NULL,
    [SourceAddedDateTime] DATETIME2 (7)  NULL,
    CONSTRAINT [PK_Staging_Transactions] PRIMARY KEY CLUSTERED ([StagingID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Staging_Transactions_CurrencyCode] FOREIGN KEY ([CurrencyCode]) REFERENCES [dbo].[CurrencyCode] ([CurrencyCode]),
    CONSTRAINT [FK_Staging_Transactions_CustomerID] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer] ([CustomerID]),
    CONSTRAINT [FK_Staging_Transactions_EarningSourceID] FOREIGN KEY ([EarningSourceID]) REFERENCES [dbo].[EarningSource] ([EarningSourceID]),
    CONSTRAINT [FK_Staging_Transactions_OfferID] FOREIGN KEY ([OfferID]) REFERENCES [dbo].[Offer] ([OfferID]),
    CONSTRAINT [FK_Staging_Transactions_PaymentCardID] FOREIGN KEY ([PaymentCardID]) REFERENCES [dbo].[PaymentCard] ([PaymentCardID]),
    CONSTRAINT [FK_Staging_Transactions_PaymentMethodID] FOREIGN KEY ([PaymentMethodID]) REFERENCES [dbo].[PaymentMethod] ([PaymentMethodID]),
    CONSTRAINT [FK_Staging_Transactions_PublisherID] FOREIGN KEY ([PublisherID]) REFERENCES [dbo].[Publisher] ([PublisherID]),
    CONSTRAINT [FK_Staging_Transactions_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);


GO
ALTER TABLE [Staging].[Transactions] NOCHECK CONSTRAINT [FK_Staging_Transactions_CurrencyCode];


GO
ALTER TABLE [Staging].[Transactions] NOCHECK CONSTRAINT [FK_Staging_Transactions_CustomerID];


GO
ALTER TABLE [Staging].[Transactions] NOCHECK CONSTRAINT [FK_Staging_Transactions_EarningSourceID];


GO
ALTER TABLE [Staging].[Transactions] NOCHECK CONSTRAINT [FK_Staging_Transactions_OfferID];


GO
ALTER TABLE [Staging].[Transactions] NOCHECK CONSTRAINT [FK_Staging_Transactions_PaymentCardID];


GO
ALTER TABLE [Staging].[Transactions] NOCHECK CONSTRAINT [FK_Staging_Transactions_PaymentMethodID];


GO
ALTER TABLE [Staging].[Transactions] NOCHECK CONSTRAINT [FK_Staging_Transactions_PublisherID];


GO
ALTER TABLE [Staging].[Transactions] NOCHECK CONSTRAINT [FK_Staging_Transactions_SourceTypeID];


GO
CREATE NONCLUSTERED INDEX [NIX_Staging_Transactions_TranDate]
    ON [Staging].[Transactions]([TranDate] ASC) WITH (FILLFACTOR = 90);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_Staging_Transactions_Source]
    ON [Staging].[Transactions]([SourceTypeID] ASC, [SourceID] ASC) WITH (FILLFACTOR = 90);

