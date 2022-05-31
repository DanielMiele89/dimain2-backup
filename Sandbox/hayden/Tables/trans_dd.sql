CREATE TABLE [hayden].[trans_dd] (
    [FileID]                   INT    NULL,
    [RowNum]                   INT    NULL,
    [Amount]                   MONEY  NULL,
    [TranDate]                 DATE   NULL,
    [BankAccountID]            INT    NULL,
    [FanID]                    INT    NULL,
    [ConsumerCombinationID_DD] BIGINT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [hayden].[trans_dd]([FileID] ASC, [RowNum] ASC);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [hayden].[trans_dd]([TranDate] ASC);

