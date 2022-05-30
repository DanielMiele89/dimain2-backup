CREATE TABLE [Processing].[TransactionPerturbation_MIDI] (
    [TransSequenceID]           BINARY (32)     NOT NULL,
    [ProxyUserID]               BINARY (32)     NOT NULL,
    [PerturbedDate]             DATE            NOT NULL,
    [ProxyMID]                  VARCHAR (MAX)   NOT NULL,
    [MCC]                       VARCHAR (4)     NOT NULL,
    [MerchantDescriptor]        VARCHAR (25)    NOT NULL,
    [CountryCode]               VARCHAR (3)     NOT NULL,
    [LocationAddress]           VARCHAR (50)    NULL,
    [OriginatorID]              VARCHAR (11)    NOT NULL,
    [TempProxyMIDTupleID]       BINARY (32)     NOT NULL,
    [PerturbedAmount]           DECIMAL (15, 8) NOT NULL,
    [CurrencyCode]              VARCHAR (3)     NOT NULL,
    [CardholderPresentFlag]     VARCHAR (3)     NOT NULL,
    [CardType]                  VARCHAR (10)    NOT NULL,
    [CardholderPostcode]        VARCHAR (10)    NULL,
    [REW_TransSequenceID_INT]   DECIMAL (10, 8) NOT NULL,
    [REW_FanID]                 INT             NOT NULL,
    [REW_SourceUID]             VARCHAR (20)    NOT NULL,
    [REW_TranDate]              DATE            NOT NULL,
    [REW_Narrative]             VARCHAR (50)    NOT NULL,
    [REW_MID]                   VARCHAR (50)    NOT NULL,
    [REW_Amount]                MONEY           NULL,
    [REW_Variance]              DECIMAL (12, 5) NOT NULL,
    [REW_RandomNumber]          DECIMAL (7, 5)  NOT NULL,
    [REW_FileID]                INT             NOT NULL,
    [REW_RowNum]                INT             NOT NULL,
    [REW_Prefix]                VARCHAR (10)    NULL,
    [REW_CardholderPresentData] TINYINT         NULL,
    [REW_CardholderPostcode]    VARCHAR (5)     NULL,
    [REW_LocationID]            INT             NULL,
    [FileDate]                  DATE            NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_Processing_miditransactionsperturbation]
    ON [Processing].[TransactionPerturbation_MIDI]([REW_FileID] ASC, [REW_RowNum] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Holds the transformed transactions, from the Processing.ConsumerTransaction_MIDI_* tables, with any required obfuscated data along with the required, non-obfuscated columns', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A hashed value that represents a unique identifier for each transaction -- it is generally [Prefix][FileID][,][RowNum]', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'TransSequenceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The hash of the "FanID + 2384,SourceUID" with the comma included in the hash; this is for Client facing CustomerID', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'ProxyUserID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date, perturbed, deterministic -- further information in documentation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'PerturbedDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MID encoded as Base64 for Client facing MIDs', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'ProxyMID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Merchant Category Code as found on the MCCList', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'MCC';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Masked version of the narrative, where applicable, otherwise, the Narrative as found on the ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'MerchantDescriptor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CountryCode as found on the LocationCountry for a ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'CountryCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The OriginatorID as found on MIDI Holding transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'OriginatorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A Hashed value that represents the MIDI Combination -- This is only temporary since, although the hashing is the same as for Processing.ConsumerCombination, it uses the whole narrative rather than a High Varianced version', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'TempProxyMIDTupleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The amount, perturbed, non-deterministic -- further information in documentation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'PerturbedAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'''GBP''', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'CurrencyCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The recoded CardholderPresentData as found in Processing.CardholderPresentData', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'CardholderPresentFlag';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'C'' for Credit, ''D'' for Debit', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'CardType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Cardholder Postal Area i.e. for a Postcode of SW17 4RT, the Post Area will be SW', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'CardholderPostcode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'An integer representation of the TransSequenceID bytes -- this is used to create an arbitrary, deterministic value that can be used to perturb the date', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_TransSequenceID_INT';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The FanID for linking between Client facing data and internal data', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_FanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Customer SourceUID as found on Fan', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_SourceUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The non-perturbed tran date as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_TranDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The full Narrative from MIDI holding', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_Narrative';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The non-encoded MID as found on MIDI Holding', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_MID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The non-perturbed amount as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_Amount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The variance used to perturb the amount', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_Variance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The random number used to perturb the transaction amount', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_RandomNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The FileID as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_FileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The RowNum as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_RowNum';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The prefix used to identify a source of transactions and to prefix to the TransSequenceID hashing algorithm', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_Prefix';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CardholderPresentData as held on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_CardholderPresentData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Postcode District as found on Relational.Customer (e.g. SW17)', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'REW_CardholderPostcode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date that the file was created', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation_MIDI', @level2type = N'COLUMN', @level2name = N'FileDate';

