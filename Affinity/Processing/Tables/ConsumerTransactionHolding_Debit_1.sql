CREATE TABLE [Processing].[ConsumerTransactionHolding_Debit] (
    [FileID]                 INT     NOT NULL,
    [RowNum]                 INT     NOT NULL,
    [ConsumerCombinationID]  INT     NOT NULL,
    [SecondaryCombinationID] INT     NULL,
    [BankID]                 TINYINT NOT NULL,
    [LocationID]             INT     NOT NULL,
    [CardholderPresentData]  TINYINT NOT NULL,
    [TranDate]               DATE    NULL,
    [CINID]                  INT     NOT NULL,
    [Amount]                 MONEY   NOT NULL,
    [IsRefund]               BIT     NOT NULL,
    [IsOnline]               BIT     NOT NULL,
    [InputModeID]            TINYINT NULL,
    [PostStatusID]           TINYINT NOT NULL,
    [PaymentTypeID]          TINYINT NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PK_ConsumerTransaction_DebitCardHolding]
    ON [Processing].[ConsumerTransactionHolding_Debit]([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated Staging table table for Debit Transactions from ConsumerTransaction and ConsumerTransaction_Holding to load into TransactionPerturbation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'FileID as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'FileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The RowNum as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'RowNum';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ConsumerCombinationID for linking between Client facing data and internal data', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'ConsumerCombinationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'SecondaryCombinationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'BankID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'LocationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CardholderPresentData as held on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'CardholderPresentData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date of the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'TranDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'CINID as found on the CINList table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'CINID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The spend of the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'Amount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'IsRefund';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'IsOnline';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQURIED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'InputModeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'PostStatusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Used to identify whether a transaction is Debit or Credit', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_Debit', @level2type = N'COLUMN', @level2name = N'PaymentTypeID';

