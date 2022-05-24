CREATE TABLE [MIDI].[CTLoad_MIDINewCombo_Old] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [MID]               VARCHAR (50)  NOT NULL,
    [Narrative]         VARCHAR (50)  NOT NULL,
    [Narrative_Cleaned] VARCHAR (250) NULL,
    [LocationCountry]   VARCHAR (3)   NOT NULL,
    [MCCID]             SMALLINT      NOT NULL,
    [IsHighVariance]    BIT           CONSTRAINT [DF_MIDI_CTLoad_MIDINewCombo_RF_IsHighVariance] DEFAULT ((0)) NOT NULL,
    [SuggestedBrandID]  SMALLINT      NULL,
    [MatchType]         TINYINT       NULL,
    [MatchCount]        INT           CONSTRAINT [DF_MIDI_CTLoad_MIDINewCombo_RF] DEFAULT ((1)) NULL,
    [BrandProbability]  FLOAT (53)    NULL,
    [IsUKSpend]         BIT           NULL,
    [IsPrefixRemoved]   BIT           NULL,
    CONSTRAINT [PK_MIDI_CTLoad_MIDINewCombo_RF] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [MIDI].[CTLoad_MIDINewCombo_Old]([LocationCountry] ASC, [MCCID] ASC, [MID] ASC, [Narrative_Cleaned] ASC, [Narrative] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff2]
    ON [MIDI].[CTLoad_MIDINewCombo_Old]([MID] ASC, [LocationCountry] ASC, [MCCID] ASC)
    INCLUDE([Narrative_Cleaned], [Narrative]);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff3]
    ON [MIDI].[CTLoad_MIDINewCombo_Old]([MID] ASC, [MCCID] ASC);

