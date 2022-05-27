CREATE TABLE [MIDI].[CTLoad_MIDINewCombo] (
    [ID]                                  INT             IDENTITY (1, 1) NOT NULL,
    [MID]                                 VARCHAR (50)    NOT NULL,
    [LocationCountry]                     VARCHAR (3)     NOT NULL,
    [MCCID]                               SMALLINT        NOT NULL,
    [OriginatorID]                        VARCHAR (11)    NULL,
    [IsUKSpend]                           BIT             NULL,
    [MatchType]                           TINYINT         NULL,
    [MatchCount]                          INT             NULL,
    [BrandProbability]                    DECIMAL (19, 4) NULL,
    [OriginalBrand_FirstMostCommonMCCID]  SMALLINT        NULL,
    [OriginalBrand_SecondMostCommonMCCID] SMALLINT        NULL,
    [OriginalBrand_ThirdMostCommonMCCID]  SMALLINT        NULL,
    [DoMCCsMatch]                         BIT             NULL,
    [OriginalBrandID]                     SMALLINT        NULL,
    [UpdatedBrandID]                      SMALLINT        NULL,
    [Narrative_Cleaned]                   VARCHAR (250)   NULL,
    [OriginalNarrative]                   VARCHAR (100)   NOT NULL,
    [UpdatedNarrative]                    VARCHAR (100)   NULL,
    [IsHighVariance]                      BIT             NULL,
    [NarrativeCount]                      INT             NULL,
    [NarrativeCount_PartialLeft]          INT             NULL,
    [NarrativeCount_PartialRight]         INT             NULL,
    [BrandCount]                          INT             NULL,
    [IsCreditOrigin]                      BIT             NULL,
    CONSTRAINT [PK_MIDI_CTLoad_MIDINewCombo] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [MIDI].[CTLoad_MIDINewCombo]([LocationCountry] ASC, [MCCID] ASC, [MID] ASC, [Narrative_Cleaned] ASC, [OriginalNarrative] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff2]
    ON [MIDI].[CTLoad_MIDINewCombo]([MID] ASC, [LocationCountry] ASC, [MCCID] ASC)
    INCLUDE([Narrative_Cleaned], [OriginalNarrative]);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff3]
    ON [MIDI].[CTLoad_MIDINewCombo]([MID] ASC, [MCCID] ASC) WITH (STATISTICS_NORECOMPUTE = ON);

