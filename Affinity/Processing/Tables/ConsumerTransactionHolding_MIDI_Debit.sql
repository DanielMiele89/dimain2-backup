CREATE TABLE [Processing].[ConsumerTransactionHolding_MIDI_Debit] (
    [FileID]                INT          NOT NULL,
    [RowNum]                INT          NOT NULL,
    [CINID]                 INT          NULL,
    [TranDate]              DATE         NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [MCCID]                 SMALLINT     NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [OriginatorID]          VARCHAR (11) NOT NULL,
    [Amount]                MONEY        NOT NULL,
    [CardholderPresentData] TINYINT      NOT NULL,
    [PaymentTypeID]         TINYINT      NOT NULL,
    [LocationAddress]       VARCHAR (20) NULL,
    [LocationID]            INT          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PK_ConsumerTransaction_MIDI_DebitCardHolding]
    ON [Processing].[ConsumerTransactionHolding_MIDI_Debit]([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated Staging table table for Debit Transactions from CTLoad_MIDI_Holding to load into TransactionPerturbation_MIDI', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'FileID as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'FileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The RowNum as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'RowNum';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'CINID as found on the CINList table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'CINID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date of the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'TranDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MID as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'MID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MCCID as found on the MCCList', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'MCCID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Raw Narrative as found on MIDI Holding transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'Narrative';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CountryCode as found on the LocationCountry for a ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'LocationCountry';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The OriginatorID as found on MIDI Holding transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'OriginatorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The spend of the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'Amount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CardholderPresentData as held on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'CardholderPresentData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Used to identify whether a transaction is Debit or Credit', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerTransactionHolding_MIDI_Debit', @level2type = N'COLUMN', @level2name = N'PaymentTypeID';

