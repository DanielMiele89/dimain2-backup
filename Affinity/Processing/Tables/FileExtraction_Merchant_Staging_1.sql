CREATE TABLE [Processing].[FileExtraction_Merchant_Staging] (
    [RewardProxyMIDTupleID] BINARY (32)   NOT NULL,
    [MCCCode]               VARCHAR (50)  NULL,
    [RewardProxyMID]        VARCHAR (MAX) NOT NULL,
    [MerchantDescriptor]    VARCHAR (50)  NULL,
    [MerchantPostcode]      VARCHAR (50)  NULL,
    [MerchantName]          VARCHAR (50)  NULL,
    [MerchantLocation]      VARCHAR (50)  NULL,
    [CountryCode]           VARCHAR (3)   NOT NULL,
    [LoopID]                INT           IDENTITY (1, 1) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucix_Processing_extract_merchant]
    ON [Processing].[FileExtraction_Merchant_Staging]([LoopID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated Staging table table to hold rows that need to be extracted for the Merchant File so that they can be looped over to provide files that only contain up to a maximum number of rows', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A Hashed value that represents the ConsumerCombination -- this is to be used instead of a ConsumerCombinationID for Client facing files', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging', @level2type = N'COLUMN', @level2name = N'RewardProxyMIDTupleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Merchant Category Code as found on the MCCList', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging', @level2type = N'COLUMN', @level2name = N'MCCCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MID encoded as Base64 for Client facing MIDs', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging', @level2type = N'COLUMN', @level2name = N'RewardProxyMID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Masked version of the narrative, where applicable, otherwise, the Narrative as found on the ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging', @level2type = N'COLUMN', @level2name = N'MerchantDescriptor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Postcode as found on CBP_Credit_TransactionHistory', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging', @level2type = N'COLUMN', @level2name = N'MerchantPostcode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Brand Name as found on Relational.Brand', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging', @level2type = N'COLUMN', @level2name = N'MerchantName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The LocationAddress as found on Relational.Location', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging', @level2type = N'COLUMN', @level2name = N'MerchantLocation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CountryCode as found on the LocationCountry for a ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging', @level2type = N'COLUMN', @level2name = N'CountryCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'An incrementing ID to be looped over to create files with a set number of rows', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'FileExtraction_Merchant_Staging', @level2type = N'COLUMN', @level2name = N'LoopID';

