CREATE TABLE [Processing].[FileExtraction_Transaction_Staging] (
    [TransSequenceID]       BINARY (32)     NOT NULL,
    [RewardProxyUserID]     BINARY (32)     NOT NULL,
    [PerturbedDate]         DATE            NOT NULL,
    [RewardProxyMIDTupleID] BINARY (32)     NOT NULL,
    [PerturbedAmount]       DECIMAL (15, 8) NOT NULL,
    [CurrencyCode]          VARCHAR (3)     NOT NULL,
    [CardholderPresentFlag] VARCHAR (3)     NOT NULL,
    [CardType]              VARCHAR (10)    NOT NULL,
    [CardholderPostArea]    VARCHAR (10)    NULL,
    [LoopID]                INT             IDENTITY (1, 1) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucix_Processing_extract_trans]
    ON [Processing].[FileExtraction_Transaction_Staging]([LoopID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated Staging table table to hold rows that need to be extracted for the Transaction File so that they can be looped over to provide files that only contain up to a maximum number of rows', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A hashed value that represents a unique identifier for each transaction -- it is generally [Prefix][FileID][,][RowNum]', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'TransSequenceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The hash of the "FanID + 2384,SourceUID" with the comma included in the hash; this is for Client facing CustomerID', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'RewardProxyUserID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The date, perturbed, deterministic -- further information in documentation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'PerturbedDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A Hashed value that represents the ConsumerCombination -- this is to be used instead of a ConsumerCombinationID for Client facing files', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'RewardProxyMIDTupleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The amount, perturbed, non-deterministic -- further information in documentation', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'PerturbedAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'''GBP''', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'CurrencyCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The recoded CardholderPresentData as found in Processing.CardholderPresentData', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'CardholderPresentFlag';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'C'' for Credit, ''D'' for Debit', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'CardType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Cardholder Postal Area i.e. for a Postcode of SW17 4RT, the Post Area will be SW', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'CardholderPostArea';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'An incrementing ID to be looped over to create files with a set number of rows', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Transaction_Staging', @level2type = N'COLUMN', @level2name = N'LoopID';

