CREATE TABLE [Processing].[Masking_CombinationsToLightHeavyMask] (
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
CREATE CLUSTERED INDEX [cix_affinity_masking_combostomask]
    ON [Processing].[Masking_CombinationsToLightHeavyMask]([Narrative] ASC);

