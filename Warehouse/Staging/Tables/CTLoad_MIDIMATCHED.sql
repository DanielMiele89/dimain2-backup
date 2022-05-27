CREATE TABLE [Staging].[CTLoad_MIDIMATCHED] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [MID]              VARCHAR (50) NOT NULL,
    [Narrative]        VARCHAR (50) NOT NULL,
    [LocationCountry]  VARCHAR (3)  NOT NULL,
    [MCCID]            SMALLINT     NOT NULL,
    [OriginatorID]     VARCHAR (11) NOT NULL,
    [IsHighVariance]   BIT          NOT NULL,
    [SuggestedBrandID] SMALLINT     NULL,
    [IsUKSpend]        BIT          NULL,
    CONSTRAINT [PK_Staging_CTLoad_MIDIMATCHED] PRIMARY KEY CLUSTERED ([ID] ASC)
);

