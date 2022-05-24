﻿CREATE TABLE [Trans].[ConsumerTransaction] (
    [ID]                     BIGINT        IDENTITY (1, 1) NOT NULL,
    [FileID]                 INT           NOT NULL,
    [RowNum]                 INT           NOT NULL,
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
    INCLUDE([FileID], [RowNum], [ConsumerCombinationID], [Amount], [IsOnline]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE ON PARTITIONS (42), DATA_COMPRESSION = PAGE ON PARTITIONS (41), DATA_COMPRESSION = PAGE ON PARTITIONS (40), DATA_COMPRESSION = PAGE ON PARTITIONS (37), DATA_COMPRESSION = PAGE ON PARTITIONS (38), DATA_COMPRESSION = PAGE ON PARTITIONS (39), DATA_COMPRESSION = PAGE ON PARTITIONS (29), DATA_COMPRESSION = PAGE ON PARTITIONS (30), DATA_COMPRESSION = PAGE ON PARTITIONS (31), DATA_COMPRESSION = PAGE ON PARTITIONS (32), DATA_COMPRESSION = PAGE ON PARTITIONS (33), DATA_COMPRESSION = PAGE ON PARTITIONS (34), DATA_COMPRESSION = PAGE ON PARTITIONS (35), DATA_COMPRESSION = PAGE ON PARTITIONS (36), DATA_COMPRESSION = PAGE ON PARTITIONS (20), DATA_COMPRESSION = PAGE ON PARTITIONS (21), DATA_COMPRESSION = PAGE ON PARTITIONS (22), DATA_COMPRESSION = PAGE ON PARTITIONS (23), DATA_COMPRESSION = PAGE ON PARTITIONS (24), DATA_COMPRESSION = PAGE ON PARTITIONS (25), DATA_COMPRESSION = PAGE ON PARTITIONS (26), DATA_COMPRESSION = PAGE ON PARTITIONS (27), DATA_COMPRESSION = PAGE ON PARTITIONS (28))
    ON [PartitionByMonthScheme] ([TranDate]);


GO
CREATE NONCLUSTERED INDEX [ix_ConsumerTrans_ConsumerCombinationID]
    ON [Trans].[ConsumerTransaction]([ConsumerCombinationID] ASC, [TranDate] ASC, [CINID] ASC, [IsOnline] ASC, [IsRefund] ASC, [BankID] ASC, [CardholderPresentData] ASC)
    INCLUDE([Amount]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE ON PARTITIONS (29), DATA_COMPRESSION = PAGE ON PARTITIONS (28), DATA_COMPRESSION = PAGE ON PARTITIONS (27), DATA_COMPRESSION = PAGE ON PARTITIONS (26), DATA_COMPRESSION = PAGE ON PARTITIONS (25), DATA_COMPRESSION = PAGE ON PARTITIONS (24), DATA_COMPRESSION = PAGE ON PARTITIONS (23), DATA_COMPRESSION = PAGE ON PARTITIONS (22), DATA_COMPRESSION = PAGE ON PARTITIONS (21), DATA_COMPRESSION = PAGE ON PARTITIONS (20), DATA_COMPRESSION = PAGE ON PARTITIONS (37), DATA_COMPRESSION = PAGE ON PARTITIONS (36), DATA_COMPRESSION = PAGE ON PARTITIONS (35), DATA_COMPRESSION = PAGE ON PARTITIONS (34), DATA_COMPRESSION = PAGE ON PARTITIONS (33), DATA_COMPRESSION = PAGE ON PARTITIONS (32), DATA_COMPRESSION = PAGE ON PARTITIONS (31), DATA_COMPRESSION = PAGE ON PARTITIONS (30), DATA_COMPRESSION = PAGE ON PARTITIONS (39), DATA_COMPRESSION = PAGE ON PARTITIONS (38), DATA_COMPRESSION = PAGE ON PARTITIONS (40), DATA_COMPRESSION = PAGE ON PARTITIONS (41), DATA_COMPRESSION = PAGE ON PARTITIONS (42))
    ON [PartitionByMonthScheme] ([TranDate]);


GO
CREATE COLUMNSTORE INDEX [csx_ConsumerTrans]
    ON [Trans].[ConsumerTransaction]([TranDate], [CINID], [ConsumerCombinationID], [BankID], [Amount], [IsRefund], [IsOnline], [CardholderPresentData], [FileID], [RowNum])
    ON [PartitionByMonthScheme] ([TranDate]);


GO
ALTER INDEX [csx_ConsumerTrans]
    ON [Trans].[ConsumerTransaction] DISABLE;

