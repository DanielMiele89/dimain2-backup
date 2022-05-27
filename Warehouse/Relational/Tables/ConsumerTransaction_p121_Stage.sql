CREATE TABLE [Relational].[ConsumerTransaction_p121_Stage] (
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
    [PaymentTypeID]          TINYINT CONSTRAINT [DF_Relational_ConsumerTransaction_p121_Stage_PaymentTypeID] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Relational_ConsumerTransaction_p121_Stage] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 90) ON [fgCTrans202206],
    CONSTRAINT [CheckTranDate_p121] CHECK ([TranDate]>='20220601' AND [TranDate]<'20220701'),
    CONSTRAINT [FK_Relational_ConsumerTransaction_p121_Stage_CardInputMode] FOREIGN KEY ([InputModeID]) REFERENCES [Relational].[CardInputMode] ([InputModeID]),
    CONSTRAINT [FK_Relational_ConsumerTransaction_p121_Stage_Combination] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Relational].[ConsumerCombination] ([ConsumerCombinationID]),
    CONSTRAINT [FK_Relational_ConsumerTransaction_p121_Stage_PostStatus] FOREIGN KEY ([PostStatusID]) REFERENCES [Relational].[PostStatus] ([PostStatusID])
) ON [fgCTrans202206];


GO
CREATE NONCLUSTERED INDEX [IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery]
    ON [Relational].[ConsumerTransaction_p121_Stage]([CINID] ASC, [TranDate] ASC)
    INCLUDE([FileID], [RowNum], [ConsumerCombinationID], [LocationID], [Amount], [IsOnline]) WITH (FILLFACTOR = 90)
    ON [fgCTrans202206];


GO
CREATE NONCLUSTERED INDEX [IX_ConsumerTransaction_MainCover]
    ON [Relational].[ConsumerTransaction_p121_Stage]([ConsumerCombinationID] ASC, [TranDate] ASC, [CINID] ASC, [IsOnline] ASC, [IsRefund] ASC, [BankID] ASC, [CardholderPresentData] ASC)
    INCLUDE([Amount]) WITH (FILLFACTOR = 90)
    ON [fgCTrans202206];

