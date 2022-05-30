CREATE TABLE [dbo].[ConsumerCombination_Masked] (
    [ConsumerCombinationID] INT          NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [MCCID]                 INT          NOT NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [MaskedNarrative]       VARCHAR (70) NOT NULL,
    [isBlanketMasked]       BIT          NOT NULL,
    [isSensitiveMasked]     BIT          NOT NULL,
    [isHeavyMasked]         BIT          NOT NULL,
    [isLightMasked]         BIT          NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucix_affinity_combination_masked]
    ON [dbo].[ConsumerCombination_Masked]([ConsumerCombinationID] ASC);

