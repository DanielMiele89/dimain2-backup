CREATE TABLE [dbo].[Masking_NarrativeRules] (
    [NarrativeRule]   VARCHAR (20) NOT NULL,
    [isHeavyMaskRule] BIT          NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_Processing_masking_narrativerules]
    ON [dbo].[Masking_NarrativeRules]([NarrativeRule] ASC, [isHeavyMaskRule] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Holds the sensitive narratives that should be considered for Heavy and Light Masking logic', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_NarrativeRules';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The LIKE logic to be used for sensitive narrative matching', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_NarrativeRules', @level2type = N'COLUMN', @level2name = N'NarrativeRule';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifies whether the rule is for Heavy Masking (if it is not, it is for Light Masking)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Masking_NarrativeRules', @level2type = N'COLUMN', @level2name = N'isHeavyMaskRule';

