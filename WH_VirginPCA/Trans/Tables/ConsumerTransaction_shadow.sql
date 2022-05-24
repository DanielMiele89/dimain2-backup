CREATE TABLE [Trans].[ConsumerTransaction_shadow] (
    [TransactionID]          VARCHAR (100) NOT NULL,
    [FileID]                 INT           NOT NULL,
    [RowNum]                 VARCHAR (100) NOT NULL,
    [ConsumerCombinationID]  INT           NOT NULL,
    [SecondaryCombinationID] INT           NULL,
    [BankID]                 SMALLINT      NULL,
    [CardholderPresentData]  TINYINT       NOT NULL,
    [TranDate]               DATETIME2 (0) NOT NULL,
    [CINID]                  INT           NOT NULL,
    [Amount]                 MONEY         NOT NULL,
    [IsRefund]               BIT           NOT NULL,
    [IsOnline]               BIT           NOT NULL,
    [InputModeID]            TINYINT       NOT NULL,
    [PaymentTypeID]          TINYINT       CONSTRAINT [DF_ConsumerTransaction_shadow_PaymentTypeID] DEFAULT ((2)) NOT NULL,
    CONSTRAINT [PK_ConsumerTrans_shadow] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 95),
    CONSTRAINT [CheckTranDate_shadow] CHECK ([TranDate]>='20210601' AND [TranDate]<'20210701'),
    CONSTRAINT [FK_Relational_ConsumerTransaction_shadow_Combination] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Trans].[ConsumerCombination] ([ConsumerCombinationID])
);


GO
CREATE NONCLUSTERED INDEX [ix_ConsumerTrans_shadow_CINID]
    ON [Trans].[ConsumerTransaction_shadow]([CINID] ASC, [TranDate] ASC)
    INCLUDE([FileID], [RowNum], [ConsumerCombinationID], [Amount], [IsOnline]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_ConsumerTrans_shadow_ConsumerCombinationID]
    ON [Trans].[ConsumerTransaction_shadow]([ConsumerCombinationID] ASC, [TranDate] ASC, [CINID] ASC, [IsOnline] ASC, [IsRefund] ASC, [BankID] ASC, [CardholderPresentData] ASC)
    INCLUDE([Amount]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE COLUMNSTORE INDEX [csx_ConsumerTrans_shadow]
    ON [Trans].[ConsumerTransaction_shadow]([TranDate], [CINID], [ConsumerCombinationID], [BankID], [Amount], [IsRefund], [IsOnline], [CardholderPresentData], [FileID], [RowNum]);

