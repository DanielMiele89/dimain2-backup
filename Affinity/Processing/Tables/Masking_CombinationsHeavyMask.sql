CREATE TABLE [Processing].[Masking_CombinationsHeavyMask] (
    [ConsumerCombinationID] INT          NULL,
    [Narrative]             VARCHAR (50) NULL,
    [MaskedNarrative]       VARCHAR (50) NULL,
    [LocationCountry]       VARCHAR (3)  NULL,
    [MCCID]                 INT          NULL,
    [MID]                   VARCHAR (50) NULL,
    [isGB]                  BIT          NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [cix_Processing_masking_heavymask]
    ON [Processing].[Masking_CombinationsHeavyMask]([ConsumerCombinationID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated Staging table table that holds ConsumerCombinations that have been run through the heavy masking logic i.e. these are only the Combinations that have had some masking applied', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsHeavyMask';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ConsumerCombinationID for linking between Client facing data and internal data', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsHeavyMask', @level2type = N'COLUMN', @level2name = N'ConsumerCombinationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Narrative as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsHeavyMask', @level2type = N'COLUMN', @level2name = N'Narrative';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Heavy Masked version of the narrative', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsHeavyMask', @level2type = N'COLUMN', @level2name = N'MaskedNarrative';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The CountryCode as found on the LocationCountry for a ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsHeavyMask', @level2type = N'COLUMN', @level2name = N'LocationCountry';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MCCID as found on the MCCList', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsHeavyMask', @level2type = N'COLUMN', @level2name = N'MCCID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The MID as found on ConsumerCombination', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsHeavyMask', @level2type = N'COLUMN', @level2name = N'MID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifies whether a ConsumerCombination is a GB combination or not', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_CombinationsHeavyMask', @level2type = N'COLUMN', @level2name = N'isGB';

