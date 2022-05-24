CREATE TABLE [Relational].[ConsumerTransactionTest] (
    [FileID]                 INT     NOT NULL,
    [RowNum]                 INT     NOT NULL,
    [ConsumerCombinationID]  INT     NOT NULL,
    [SecondaryCombinationID] INT     NULL,
    [BankID]                 TINYINT NOT NULL,
    [LocationID]             INT     NOT NULL,
    [CardholderPresentData]  TINYINT NOT NULL,
    [TranDate]               DATE    NOT NULL,
    [CINID]                  INT     NOT NULL,
    [Amount]                 MONEY   NOT NULL,
    [IsRefund]               BIT     NOT NULL,
    [IsOnline]               BIT     NOT NULL,
    [InputModeID]            TINYINT NOT NULL,
    [PostStatusID]           TINYINT NOT NULL,
    [PaymentTypeID]          TINYINT CONSTRAINT [DF_Relational_ConsumerTransactionTest_Partitioned_PaymentTypeID] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Relational_ConsumerTransactionTest_Partitioned] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Relational_ConsumerTransactionTest_MyRewards_Partitioned_Combination] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Relational].[ConsumerCombination] ([ConsumerCombinationID]),
    CONSTRAINT [FK_Relational_ConsumerTransactionTest_Partitioned_CardInputMode] FOREIGN KEY ([InputModeID]) REFERENCES [Relational].[CardInputMode] ([InputModeID]),
    CONSTRAINT [FK_Relational_ConsumerTransactionTest_Partitioned_Combination] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Relational].[ConsumerCombination] ([ConsumerCombinationID]),
    CONSTRAINT [FK_Relational_ConsumerTransactionTest_Partitioned_PostStatus] FOREIGN KEY ([PostStatusID]) REFERENCES [Relational].[PostStatus] ([PostStatusID])
);


GO
ALTER TABLE [Relational].[ConsumerTransactionTest] SET (LOCK_ESCALATION = AUTO);

