CREATE TABLE [Staging].[stage2_Trimmed_CleanedConsumerCombination] (
    [ConsumerCombinationID]  INT          NOT NULL,
    [SectorID]               TINYINT      NULL,
    [BrandMIDID]             INT          NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MCCID]                  SMALLINT     NOT NULL,
    [OriginatorID]           VARCHAR (11) NOT NULL,
    [TrimedCleanedNarrative] VARCHAR (50) NOT NULL
);

