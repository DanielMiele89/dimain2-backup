CREATE TABLE [Staging].[ConsumerTransaction_DD_Holding] (
    [FileID]                   INT   NOT NULL,
    [RowNum]                   INT   NOT NULL,
    [ConsumerCombinationID_DD] INT   NOT NULL,
    [TranDate]                 DATE  NOT NULL,
    [BankAccountID]            INT   NULL,
    [FanID]                    INT   NULL,
    [Amount]                   MONEY NOT NULL
);

