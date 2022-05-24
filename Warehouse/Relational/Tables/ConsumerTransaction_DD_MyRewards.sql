CREATE TABLE [Relational].[ConsumerTransaction_DD_MyRewards] (
    [FileID]                   INT    NOT NULL,
    [RowNum]                   INT    NOT NULL,
    [Amount]                   MONEY  NULL,
    [TranDate]                 DATE   NULL,
    [BankAccountID]            INT    NOT NULL,
    [FanID]                    INT    NULL,
    [ConsumerCombinationID_DD] BIGINT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UCX_FileIDRowNum]
    ON [Relational].[ConsumerTransaction_DD_MyRewards]([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

