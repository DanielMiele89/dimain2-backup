CREATE TABLE [Trans].[ConsumerTransaction_20220427] (
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
    [PaymentTypeID]          TINYINT       CONSTRAINT [DF_Trans_ConsumerTransaction_PaymentTypeID_20220427] DEFAULT ((2)) NOT NULL,
    CONSTRAINT [PK_ConsumerTrans_20220427] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 95) ON [PartitionByMonthScheme] ([TranDate]),
    CONSTRAINT [FK_Trans_ConsumerTransaction_Combination_20220427] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Trans].[ConsumerCombination_20220427] ([ConsumerCombinationID])
) ON [PartitionByMonthScheme] ([TranDate]);


GO
CREATE NONCLUSTERED INDEX [ix_ConsumerTrans_CINID]
    ON [Trans].[ConsumerTransaction_20220427]([CINID] ASC, [TranDate] ASC)
    INCLUDE([FileID], [RowNum], [ConsumerCombinationID], [Amount], [IsOnline]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE ON PARTITIONS (53), DATA_COMPRESSION = PAGE ON PARTITIONS (50), DATA_COMPRESSION = PAGE ON PARTITIONS (52), DATA_COMPRESSION = PAGE ON PARTITIONS (51))
    ON [PartitionByMonthScheme] ([TranDate]);


GO
CREATE NONCLUSTERED INDEX [ix_ConsumerTrans_ConsumerCombinationID]
    ON [Trans].[ConsumerTransaction_20220427]([ConsumerCombinationID] ASC, [TranDate] ASC, [CINID] ASC, [IsOnline] ASC, [IsRefund] ASC, [BankID] ASC, [CardholderPresentData] ASC)
    INCLUDE([Amount]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE ON PARTITIONS (53), DATA_COMPRESSION = PAGE ON PARTITIONS (51), DATA_COMPRESSION = PAGE ON PARTITIONS (50), DATA_COMPRESSION = PAGE ON PARTITIONS (52))
    ON [PartitionByMonthScheme] ([TranDate]);


GO
CREATE COLUMNSTORE INDEX [csx_ConsumerTrans]
    ON [Trans].[ConsumerTransaction_20220427]([TranDate], [CINID], [ConsumerCombinationID], [BankID], [Amount], [IsRefund], [IsOnline], [CardholderPresentData], [FileID], [RowNum])
    ON [PartitionByMonthScheme] ([TranDate]);

