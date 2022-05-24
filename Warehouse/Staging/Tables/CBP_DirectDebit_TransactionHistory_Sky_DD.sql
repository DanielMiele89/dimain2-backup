CREATE TABLE [Staging].[CBP_DirectDebit_TransactionHistory_Sky_DD] (
    [ConsumerCombination_DirectDebitID] BIGINT       NULL,
    [FileID]                            INT          NULL,
    [RowNum]                            INT          NULL,
    [OIN]                               INT          NULL,
    [Narrative]                         VARCHAR (50) NULL,
    [TranDate]                          DATE         NULL,
    [Amount]                            MONEY        NULL,
    [ClubID]                            INT          NULL,
    [BankAccountID]                     INT          NULL,
    [SourceUID]                         VARCHAR (20) NULL,
    [FanID]                             INT          NULL
);

