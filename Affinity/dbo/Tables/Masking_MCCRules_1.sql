CREATE TABLE [dbo].[Masking_MCCRules] (
    [MCCID]           INT NULL,
    [isHeavyMaskRule] BIT NULL
);


GO
CREATE CLUSTERED INDEX [cix_dbo_masking_mccrules]
    ON [dbo].[Masking_MCCRules]([MCCID] ASC, [isHeavyMaskRule] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Holds the MCCIDs that should be considered for Heavy Masking and Light Masking', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_MCCRules';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The MCCID as found on the MCCList', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_MCCRules', @level2type = N'COLUMN', @level2name = N'MCCID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifies whether the rule is for Heavy Masking (if it is not, it is for Light Masking)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_MCCRules', @level2type = N'COLUMN', @level2name = N'isHeavyMaskRule';

