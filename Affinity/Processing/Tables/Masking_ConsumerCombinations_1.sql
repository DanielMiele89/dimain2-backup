CREATE TABLE [Processing].[Masking_ConsumerCombinations] (
    [ConsumerCombinationID]  INT          NOT NULL,
    [BrandMIDID]             INT          NULL,
    [BrandID]                SMALLINT     NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MCCID]                  SMALLINT     NOT NULL,
    [OriginatorID]           VARCHAR (11) NOT NULL,
    [IsHighVariance]         BIT          NOT NULL,
    [IsUKSpend]              BIT          NOT NULL,
    [PaymentGatewayStatusID] TINYINT      NOT NULL,
    [IsCreditOrigin]         BIT          NOT NULL,
    [isGB]                   BIT          NULL,
    [isBlanketMask]          BIT          NULL,
    [rw]                     INT          NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucix_Processing_consumercombinations]
    ON [Processing].[Masking_ConsumerCombinations]([ConsumerCombinationID] ASC, [MID] ASC, [isGB] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Truncated Staging table table holding semi-transformed ConsumerCombinations that are used as the source for the Merchant File Masking ', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The ConsumerCombinationID for linking between Client facing data and internal data', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'ConsumerCombinationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'BrandMIDID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The BrandID for the ConsumerCombination, required for nFI transaction joins', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'BrandID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The MID as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'MID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The Narrative as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'Narrative';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The CountryCode as found on the LocationCountry for a ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'LocationCountry';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The MCCID as found on the MCCList', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'MCCID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The OriginatorID as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'OriginatorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'IsHighVariance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'IsUKSpend';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'PaymentGatewayStatusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NOT REQUIRED', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'IsCreditOrigin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifies whether a ConsumerCombination is a GB combination or not', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'isGB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifies whether a ConsumerCombination is to be blanket masked or put through the Heavy/Light masking routine', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'isBlanketMask';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ROWNUMBER() split by MID, BrandID ORDER BY ConsumerCombinationID DESC -- to match a single combination to nFI transaction MID', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_ConsumerCombinations', @level2type = N'COLUMN', @level2name = N'rw';

