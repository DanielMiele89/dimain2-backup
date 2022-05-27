CREATE TABLE [Relational].[ConsumerTransaction_DD] (
    [FileID]                   INT    NULL,
    [RowNum]                   INT    NULL,
    [Amount]                   MONEY  NULL,
    [TranDate]                 DATE   NULL,
    [BankAccountID]            INT    NULL,
    [FanID]                    INT    NULL,
    [ConsumerCombinationID_DD] BIGINT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UCX_FileIDRowNum]
    ON [Relational].[ConsumerTransaction_DD]([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Relational].[ConsumerTransaction_DD]([TranDate], [FanID], [Amount], [ConsumerCombinationID_DD], [BankAccountID])
    ON [Warehouse_Columnstores];

