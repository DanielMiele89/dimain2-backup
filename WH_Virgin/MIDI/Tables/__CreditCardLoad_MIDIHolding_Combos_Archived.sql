CREATE TABLE [MIDI].[__CreditCardLoad_MIDIHolding_Combos_Archived] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [OriginatorReference] VARCHAR (6)   NOT NULL,
    [LocationCountry]     VARCHAR (3)   NOT NULL,
    [MID]                 VARCHAR (50)  NOT NULL,
    [Narrative]           VARCHAR (50)  NOT NULL,
    [MCCID]               SMALLINT      NULL,
    [SuggestedBrandID]    SMALLINT      NULL,
    [MatchType]           VARCHAR (200) NULL,
    [trancount]           INT           NOT NULL,
    [IsHighVariance]      BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_staging_CreditCardLoad_MIDIHolding_Combos] PRIMARY KEY CLUSTERED ([ID] ASC)
);

