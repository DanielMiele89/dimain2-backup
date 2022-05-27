CREATE TABLE [Staging].[MIDI_ConsumerCombination_Temp] (
    [BrandID]           SMALLINT      NOT NULL,
    [MID]               VARCHAR (50)  NOT NULL,
    [Narrative]         VARCHAR (150) NOT NULL,
    [Narrative_Cleaned] VARCHAR (150) NOT NULL,
    [LocationCountry]   VARCHAR (3)   NOT NULL,
    [MCCID]             SMALLINT      NOT NULL,
    [OriginatorID]      VARCHAR (11)  NULL,
    [IsHighVariance]    BIT           NOT NULL,
    [Transactions]      INT           NULL,
    [Amount]            MONEY         NULL
);

