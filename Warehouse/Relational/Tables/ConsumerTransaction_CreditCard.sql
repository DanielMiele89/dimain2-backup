CREATE TABLE [Relational].[ConsumerTransaction_CreditCard] (
    [FileID]                 INT     NOT NULL,
    [RowNum]                 INT     NOT NULL,
    [ConsumerCombinationID]  INT     NOT NULL,
    [SecondaryCombinationID] INT     NULL,
    [CardholderPresentData]  TINYINT NOT NULL,
    [TranDate]               DATE    NOT NULL,
    [CINID]                  INT     NOT NULL,
    [Amount]                 MONEY   NOT NULL,
    [IsOnline]               BIT     NOT NULL,
    [LocationID]             INT     NOT NULL,
    [FanID]                  INT     NULL,
    CONSTRAINT [PK_ConsumerTransaction_CreditCard] PRIMARY KEY NONCLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE) ON [Warehouse_Indexes]
);


GO
CREATE CLUSTERED INDEX [cx_CT]
    ON [Relational].[ConsumerTransaction_CreditCard]([TranDate] ASC, [CINID] ASC, [ConsumerCombinationID] ASC) WITH (FILLFACTOR = 85, DATA_COMPRESSION = PAGE);

