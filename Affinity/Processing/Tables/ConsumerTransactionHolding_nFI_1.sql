CREATE TABLE [Processing].[ConsumerTransactionHolding_nFI] (
    [MerchantID]            NVARCHAR (50) NULL,
    [CardholderPresentData] INT           NULL,
    [TranDate]              DATE          NULL,
    [AddedDate]             DATETIME      NULL,
    [CompositeID]           BIGINT        NULL,
    [Amount]                MONEY         NULL,
    [CardTypeID]            TINYINT       NULL,
    [PartnerID]             INT           NULL,
    [VectorMajorID]         INT           NULL,
    [VectorMinorID]         INT           NULL,
    [TranID]                INT           NOT NULL,
    [BrandID]               INT           NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PK_ConsumerTransaction_nFICardHolding]
    ON [Processing].[ConsumerTransactionHolding_nFI]([TranID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated Staging table table to holding Debit Transactions from the Match table for various nFIs to load into TransactionPerturbation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MID as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'MerchantID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CardholderPresentData as held on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'CardholderPresentData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date of the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'TranDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'AddedDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'CompositeID as found on the Fan table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'CompositeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The spend of the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'Amount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'CardTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The PartnerID as found on Partner table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'PartnerID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'VectorMajorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'VectorMinorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ID from Match', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'TranID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The BrandID for the transaction to be used to join to a ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_nFI', @level2type = N'COLUMN', @level2name = N'BrandID';

