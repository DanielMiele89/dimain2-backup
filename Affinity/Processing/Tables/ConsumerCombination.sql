CREATE TABLE [Processing].[ConsumerCombination] (
    [ConsumerCombinationID]  INT           NOT NULL,
    [BrandMIDID]             INT           NULL,
    [BrandID]                SMALLINT      NOT NULL,
    [MID]                    VARCHAR (50)  NOT NULL,
    [Narrative]              VARCHAR (50)  NOT NULL,
    [LocationCountry]        VARCHAR (3)   NOT NULL,
    [MCCID]                  SMALLINT      NOT NULL,
    [OriginatorID]           VARCHAR (11)  NOT NULL,
    [IsHighVariance]         BIT           NOT NULL,
    [IsUKSpend]              BIT           NOT NULL,
    [PaymentGatewayStatusID] TINYINT       NOT NULL,
    [IsCreditOrigin]         BIT           NOT NULL,
    [MerchantZip]            VARCHAR (50)  NULL,
    [MCC]                    VARCHAR (50)  NULL,
    [BrandName]              VARCHAR (50)  NULL,
    [LocationAddress]        VARCHAR (50)  NULL,
    [RowNum]                 INT           NULL,
    [ProxyMIDTupleID]        BINARY (32)   NOT NULL,
    [ProxyMID]               VARCHAR (MAX) NOT NULL,
    [MaskedNarrative]        VARCHAR (50)  NULL,
    [isBlanketMasked]        BIT           NOT NULL,
    [isSensitiveMasked]      BIT           NOT NULL,
    [isHeavyMasked]          BIT           NOT NULL,
    [isLightMasked]          BIT           NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [cix_Processing_consumercombination]
    ON [Processing].[ConsumerCombination]([ConsumerCombinationID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated transformed ConsumerCombination table that has appropriate obfuscation columns along with the required, non-obfuscated version of columns', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ConsumerCombinationID for linking between Client facing data and internal data', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'ConsumerCombinationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'BrandMIDID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The BrandID for the ConsumerCombination, required for nFI transaction joins', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'BrandID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MID as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'MID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Narrative as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'Narrative';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CountryCode as found on the LocationCountry for a ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'LocationCountry';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MCCID as found on the MCCList', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'MCCID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The OriginatorID as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'OriginatorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'IsHighVariance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'IsUKSpend';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'PaymentGatewayStatusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NOT REQURIED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'IsCreditOrigin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Postcode as found on CBP_Credit_TransactionHistory', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'MerchantZip';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Merchant Category Code as found on the MCCList', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'MCC';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Brand Name as found on Relational.Brand', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'BrandName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The address as found on the Processing.MerchantLocation table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'LocationAddress';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'RowNum';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'A Hashed value that represents the ConsumerCombination -- this is to be used instead of a ConsumerCombinationID for Client facing files', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'ProxyMIDTupleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MID encoded as Base64 for Client facing MIDs', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'ProxyMID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Masked version of the narrative, where applicable, otherwise, the Narrative as found on the ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'ConsumerCombination', @level2type = N'COLUMN', @level2name = N'MaskedNarrative';

