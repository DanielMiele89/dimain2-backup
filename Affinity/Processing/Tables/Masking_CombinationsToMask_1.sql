CREATE TABLE [Processing].[Masking_CombinationsToMask] (
    [ConsumerCombinationID] INT          NULL,
    [Narrative]             VARCHAR (50) NULL,
    [MCCID]                 SMALLINT     NULL,
    [LocationCountry]       VARCHAR (3)  NULL,
    [MID]                   VARCHAR (50) NULL,
    [isGB]                  BIT          NOT NULL,
    [isBlanketMask]         BIT          NOT NULL,
    [isSensitiveMask]       BIT          NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_masking_combinationstomask]
    ON [Processing].[Masking_CombinationsToMask]([ConsumerCombinationID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Truncated Staging table table that holds the Combinations, after exemptions, that are to be considered for masking', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsToMask';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The ConsumerCombinationID for linking between Client facing data and internal data', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsToMask', @level2type = N'COLUMN', @level2name = N'ConsumerCombinationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The Narrative as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsToMask', @level2type = N'COLUMN', @level2name = N'Narrative';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The MCCID as found on the MCCList', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsToMask', @level2type = N'COLUMN', @level2name = N'MCCID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The CountryCode as found on the LocationCountry for a ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsToMask', @level2type = N'COLUMN', @level2name = N'LocationCountry';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The MID as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsToMask', @level2type = N'COLUMN', @level2name = N'MID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifies whether a ConsumerCombination is a GB combination or not', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsToMask', @level2type = N'COLUMN', @level2name = N'isGB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifies whether a ConsumerCombination is to be blanket masked or put through the Heavy/Light masking routine', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsToMask', @level2type = N'COLUMN', @level2name = N'isBlanketMask';

