CREATE TABLE [Staging].[CBP_DirectDebit_TransactionHistory_EON_DD] (
    [ConsumerCombination_DirectDebitID] BIGINT       NULL,
    [FileID]                            INT          NOT NULL,
    [RowNum]                            INT          NOT NULL,
    [OIN]                               INT          NULL,
    [Narrative]                         VARCHAR (50) NULL,
    [TranDate]                          DATE         NOT NULL,
    [Amount]                            MONEY        NULL,
    [ClubID]                            INT          NULL,
    [BankAccountID]                     INT          NULL,
    [SourceUID]                         VARCHAR (20) NULL,
    [FanID]                             INT          NULL,
    CONSTRAINT [PK_FileRowTranDate] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_FanTranDateIncl_OINAmount]
    ON [Staging].[CBP_DirectDebit_TransactionHistory_EON_DD]([FanID] ASC, [TranDate] ASC)
    INCLUDE([OIN], [Amount]);

