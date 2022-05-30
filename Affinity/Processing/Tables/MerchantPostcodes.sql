CREATE TABLE [Processing].[MerchantPostcodes] (
    [MerchantID]      VARCHAR (20) NULL,
    [MerchantZip]     VARCHAR (50) NULL,
    [MerchantDBAName] VARCHAR (50) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Processing_merchantpostcodes]
    ON [Processing].[MerchantPostcodes]([MerchantID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated table that holds the latest found Postcode from the Credit Card data for each ConsumerCombinationID', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'MerchantPostcodes';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MID as found on Relational.Postcode', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'MerchantPostcodes', @level2type = N'COLUMN', @level2name = N'MerchantID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Postcode as found on CBP_Credit_TransactionHistory', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'MerchantPostcodes', @level2type = N'COLUMN', @level2name = N'MerchantZip';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'MerchantPostcodes', @level2type = N'COLUMN', @level2name = N'MerchantDBAName';

