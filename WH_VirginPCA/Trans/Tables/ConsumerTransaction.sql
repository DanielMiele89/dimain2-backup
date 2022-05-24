CREATE TABLE [Trans].[ConsumerTransaction] (
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
    [PaymentTypeID]          TINYINT       CONSTRAINT [DF_Trans_ConsumerTransaction_PaymentTypeID] DEFAULT ((2)) NOT NULL,
    CONSTRAINT [PK_ConsumerTrans] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 95) ON [PartitionByMonthScheme] ([TranDate]),
    CONSTRAINT [FK_Trans_ConsumerTransaction_Combination] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Trans].[ConsumerCombination] ([ConsumerCombinationID])
) ON [PartitionByMonthScheme] ([TranDate]);


GO
CREATE NONCLUSTERED INDEX [ix_ConsumerTrans_CINID]
    ON [Trans].[ConsumerTransaction]([CINID] ASC, [TranDate] ASC)
    INCLUDE([FileID], [RowNum], [ConsumerCombinationID], [Amount], [IsOnline]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE ON PARTITIONS (54), DATA_COMPRESSION = PAGE ON PARTITIONS (53), DATA_COMPRESSION = PAGE ON PARTITIONS (52), DATA_COMPRESSION = PAGE ON PARTITIONS (51), DATA_COMPRESSION = PAGE ON PARTITIONS (50), DATA_COMPRESSION = PAGE ON PARTITIONS (49), DATA_COMPRESSION = PAGE ON PARTITIONS (48), DATA_COMPRESSION = PAGE ON PARTITIONS (47), DATA_COMPRESSION = PAGE ON PARTITIONS (46))
    ON [PartitionByMonthScheme] ([TranDate]);


GO
CREATE NONCLUSTERED INDEX [ix_ConsumerTrans_ConsumerCombinationID]
    ON [Trans].[ConsumerTransaction]([ConsumerCombinationID] ASC, [TranDate] ASC, [CINID] ASC, [IsOnline] ASC, [IsRefund] ASC, [BankID] ASC, [CardholderPresentData] ASC)
    INCLUDE([Amount]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE ON PARTITIONS (54), DATA_COMPRESSION = PAGE ON PARTITIONS (46), DATA_COMPRESSION = PAGE ON PARTITIONS (47), DATA_COMPRESSION = PAGE ON PARTITIONS (48), DATA_COMPRESSION = PAGE ON PARTITIONS (49), DATA_COMPRESSION = PAGE ON PARTITIONS (50), DATA_COMPRESSION = PAGE ON PARTITIONS (51), DATA_COMPRESSION = PAGE ON PARTITIONS (52), DATA_COMPRESSION = PAGE ON PARTITIONS (53))
    ON [PartitionByMonthScheme] ([TranDate]);


GO
CREATE COLUMNSTORE INDEX [csx_ConsumerTrans]
    ON [Trans].[ConsumerTransaction]([TranDate], [CINID], [ConsumerCombinationID], [BankID], [Amount], [IsRefund], [IsOnline], [CardholderPresentData], [FileID], [RowNum])
    ON [PartitionByMonthScheme] ([TranDate]);

