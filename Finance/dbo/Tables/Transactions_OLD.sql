CREATE TABLE [dbo].[Transactions_OLD] (
    [TransactionID]                          INT           IDENTITY (1, 1) NOT NULL,
    [SourceSystemID]                         INT           NOT NULL,
    [SourceID]                               INT           NOT NULL,
    [SourceTypeID]                           INT           NOT NULL,
    [FanID]                                  INT           NOT NULL,
    [IronOfferID]                            INT           NOT NULL,
    [PartnerID]                              INT           NOT NULL,
    [PublisherID]                            SMALLINT      NOT NULL,
    [Spend]                                  SMALLMONEY    NULL,
    [Earnings]                               SMALLMONEY    NULL,
    [TranDate]                               DATE          NOT NULL,
    [TransactionTypeID]                      SMALLINT      NOT NULL,
    [AdditionalCashbackAwardTypeID]          SMALLINT      NOT NULL,
    [AdditionalCashbackAdjustmentTypeID]     SMALLINT      NOT NULL,
    [AdditionalCashbackAdjustmentCategoryID] SMALLINT      NOT NULL,
    [PaymentMethodID]                        SMALLINT      NOT NULL,
    [DirectDebitOriginatorID]                INT           NULL,
    [EarningSourceID]                        SMALLINT      NULL,
    [SourceAddedDate]                        DATE          NULL,
    [CreatedDateTime]                        DATETIME2 (7) NOT NULL,
    [ActivationDays]                         INT           NULL,
    [EligibleDate]                           DATE          NULL,
    CONSTRAINT [PK_Transactions_OLD] PRIMARY KEY CLUSTERED ([TransactionID] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [FK_Transactions_AdditionalCashbackAdjustmentCategoryID_OLD] FOREIGN KEY ([AdditionalCashbackAdjustmentCategoryID]) REFERENCES [dbo].[AdditionalCashbackAdjustmentCategory_OLD] ([AdditionalCashbackAdjustmentCategoryID]),
    CONSTRAINT [FK_Transactions_AdditionalCashbackAdjustmentTypeID_OLD] FOREIGN KEY ([AdditionalCashbackAdjustmentTypeID]) REFERENCES [dbo].[AdditionalCashbackAdjustmentType_OLD] ([AdditionalCashbackAdjustmentTypeID]),
    CONSTRAINT [FK_Transactions_AdditionalCashbackAwardTypeID_OLD] FOREIGN KEY ([AdditionalCashbackAwardTypeID]) REFERENCES [dbo].[AdditionalCashbackAwardType_OLD] ([AdditionalCashbackAwardTypeID]),
    CONSTRAINT [FK_Transactions_CustomerID_OLD] FOREIGN KEY ([FanID]) REFERENCES [dbo].[Customer_OLD] ([CustomerID]),
    CONSTRAINT [FK_Transactions_IronOfferID_OLD] FOREIGN KEY ([IronOfferID]) REFERENCES [dbo].[IronOffer_OLD] ([IronOfferID]),
    CONSTRAINT [FK_Transactions_PartnerID_OLD] FOREIGN KEY ([PartnerID]) REFERENCES [dbo].[Partner_OLD] ([PartnerID]),
    CONSTRAINT [FK_Transactions_PublisherID_OLD] FOREIGN KEY ([PublisherID]) REFERENCES [dbo].[Publisher_OLD] ([PublisherID]),
    CONSTRAINT [FK_Transactions_SourceSystemID_OLD] FOREIGN KEY ([SourceSystemID]) REFERENCES [dbo].[SourceSystem_OLD] ([SourceSystemID]),
    CONSTRAINT [FK_Transactions_SourceTypeID_OLD] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType_OLD] ([SourceTypeID]),
    CONSTRAINT [FK_Transactions_TransactionTypeID_OLD] FOREIGN KEY ([TransactionTypeID]) REFERENCES [dbo].[TransactionType_OLD] ([TransactionTypeID])
);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [dbo].[Transactions_OLD]([AdditionalCashbackAdjustmentCategoryID] ASC)
    INCLUDE([Earnings], [TranDate], [AdditionalCashbackAdjustmentTypeID]);


GO
ALTER INDEX [NIX]
    ON [dbo].[Transactions_OLD] DISABLE;


GO
CREATE NONCLUSTERED INDEX [NIX_CustomerID]
    ON [dbo].[Transactions_OLD]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [NIX_TranDate]
    ON [dbo].[Transactions_OLD]([TranDate] ASC)
    INCLUDE([FanID], [Earnings], [EligibleDate], [PaymentMethodID], [EarningSourceID], [Spend]);


GO
CREATE NONCLUSTERED INDEX [NIX_QuerySource]
    ON [dbo].[Transactions_OLD]([SourceSystemID] ASC, [SourceID] ASC, [SourceTypeID] ASC);


GO
ALTER INDEX [NIX_QuerySource]
    ON [dbo].[Transactions_OLD] DISABLE;


GO
CREATE NONCLUSTERED INDEX [NIX_Earnings]
    ON [dbo].[Transactions_OLD]([Earnings] ASC)
    INCLUDE([TransactionID], [FanID], [TranDate], [AdditionalCashbackAdjustmentTypeID], [EarningSourceID], [CreatedDateTime]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [NIX_FIFO_Breakage]
    ON [dbo].[Transactions_OLD]([AdditionalCashbackAdjustmentTypeID] ASC)
    INCLUDE([TransactionID], [FanID], [Earnings], [TranDate], [PaymentMethodID], [EarningSourceID], [EligibleDate]);


GO
CREATE NONCLUSTERED INDEX [NIX_CreatedDateTime]
    ON [dbo].[Transactions_OLD]([CreatedDateTime] ASC) WITH (FILLFACTOR = 90);

