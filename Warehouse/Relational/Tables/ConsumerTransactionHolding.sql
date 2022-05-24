CREATE TABLE [Relational].[ConsumerTransactionHolding] (
    [FileID]                 INT     NOT NULL,
    [RowNum]                 INT     NOT NULL,
    [ConsumerCombinationID]  INT     NOT NULL,
    [SecondaryCombinationID] INT     NULL,
    [BankID]                 TINYINT NOT NULL,
    [LocationID]             INT     NOT NULL,
    [CardholderPresentData]  TINYINT NOT NULL,
    [TranDate]               DATE    NULL,
    [CINID]                  INT     NOT NULL,
    [Amount]                 MONEY   NOT NULL,
    [IsRefund]               BIT     NOT NULL,
    [IsOnline]               BIT     NOT NULL,
    [InputModeID]            TINYINT NULL,
    [PostStatusID]           TINYINT NOT NULL,
    [PaymentTypeID]          TINYINT CONSTRAINT [DF_Relational_ConsumerTransactionHolding_PaymentTypeID] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Relational_ConsumerTransactionHolding] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC),
    CONSTRAINT [FK_Relational_ConsumerTransactionHolding_CardInputMode] FOREIGN KEY ([InputModeID]) REFERENCES [Relational].[CardInputMode] ([InputModeID]),
    CONSTRAINT [FK_Relational_ConsumerTransactionHolding_Combination] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Relational].[ConsumerCombination] ([ConsumerCombinationID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Relational_ConsumerTransactionHolding_CINIDTranDateIncl_ForMissingTranQuery]
    ON [Relational].[ConsumerTransactionHolding]([CINID] ASC, [TranDate] ASC)
    INCLUDE([FileID], [RowNum], [ConsumerCombinationID], [LocationID], [Amount]);


GO
CREATE NONCLUSTERED INDEX [IX_ConsumerTransactionHolding_MainCover]
    ON [Relational].[ConsumerTransactionHolding]([ConsumerCombinationID] ASC, [TranDate] ASC, [CINID] ASC, [IsOnline] ASC, [IsRefund] ASC, [BankID] ASC, [CardholderPresentData] ASC)
    INCLUDE([Amount]);

