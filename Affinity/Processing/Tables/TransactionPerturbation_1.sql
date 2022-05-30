CREATE TABLE [Processing].[TransactionPerturbation] (
    [TransSequenceID]           BINARY (32)     NOT NULL,
    [ProxyUserID]               BINARY (32)     NOT NULL,
    [PerturbedDate]             DATE            NOT NULL,
    [ProxyMIDTupleID]           BINARY (32)     NOT NULL,
    [PerturbedAmount]           DECIMAL (15, 8) NOT NULL,
    [CurrencyCode]              VARCHAR (3)     NOT NULL,
    [CardholderPresentFlag]     VARCHAR (3)     NOT NULL,
    [CardType]                  VARCHAR (10)    NOT NULL,
    [CardholderPostcode]        VARCHAR (10)    NULL,
    [REW_TransSequenceID_INT]   DECIMAL (10, 8) NOT NULL,
    [REW_FanID]                 INT             NOT NULL,
    [REW_SourceUID]             VARCHAR (20)    NOT NULL,
    [REW_TranDate]              DATE            NOT NULL,
    [REW_ConsumerCombinationID] INT             NOT NULL,
    [REW_Amount]                MONEY           NULL,
    [REW_Variance]              DECIMAL (12, 5) NOT NULL,
    [REW_RandomNumber]          DECIMAL (7, 5)  NOT NULL,
    [REW_FileID]                INT             NOT NULL,
    [REW_RowNum]                INT             NOT NULL,
    [REW_Prefix]                VARCHAR (10)    NULL,
    [REW_CardholderPresentData] TINYINT         NULL,
    [REW_CardholderPostcode]    VARCHAR (5)     NULL,
    [FileType]                  VARCHAR (10)    NOT NULL,
    [FileDate]                  DATE            NOT NULL,
    [CreatedDateTime]           DATETIME        DEFAULT (getdate()) NOT NULL
);


GO
CREATE CLUSTERED INDEX [cx_FileType_FileDate]
    ON [Processing].[TransactionPerturbation]([FileType] ASC, [FileDate] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [Processing].[TransactionPerturbation]([REW_FileID] ASC, [REW_RowNum] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Holds the transformed transactions, from the Processing.ConsumerTransaction_* tables, with any required obfuscated data along with the required, non-obfuscated columns', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A hashed value that represents a unique identifier for each transaction -- it is generally [Prefix][FileID][,][RowNum]', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'TransSequenceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The hash of the "FanID + 2384,SourceUID" with the comma included in the hash; this is for Client facing CustomerID', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'ProxyUserID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date, perturbed, deterministic -- further information in documentation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'PerturbedDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The hashed ConsumerCombination from Processing.ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'ProxyMIDTupleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The amount, perturbed, non-deterministic -- further information in documentation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'PerturbedAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'''GBP''', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'CurrencyCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The recoded CardholderPresentData as found in Processing.CardholderPresentData', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'CardholderPresentFlag';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'C'' for Credit, ''D'' for Debit', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'CardType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Cardholder Postal Area i.e. for a Postcode of SW17 4RT, the Post Area will be SW', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'CardholderPostcode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'An integer representation of the TransSequenceID bytes -- this is used to create an arbitrary, deterministic value that can be used to perturb the date', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_TransSequenceID_INT';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The FanID for linking between Client facing data and internal data', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_FanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Customer SourceUID as found on Fan', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_SourceUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The non-perturbed tran date as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_TranDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ConsumerCombinationID for linking between Client facing data and internal data', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_ConsumerCombinationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The non-perturbed amount as found on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_Amount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The variance used to perturb the amount', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_Variance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The random number used to perturb the transaction amount', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_RandomNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The FileID as found on the transaction (-1 for nFI Transactions)', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_FileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The RowNum as found on the transaction (Match.ID for nFI Transactions)', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_RowNum';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The prefix used to identify a source of transactions and to prefix to the TransSequenceID hashing algorithm', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_Prefix';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CardholderPresentData as held on the transaction', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_CardholderPresentData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Postcode District as found on Relational.Customer (e.g. SW17)', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'REW_CardholderPostcode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The type of file that was created such as Daily or Historical', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'FileType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date that the file was created', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'FileDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The DATETIME that the row was inserted into the table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'TransactionPerturbation', @level2type = N'COLUMN', @level2name = N'CreatedDateTime';

