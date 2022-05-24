CREATE TABLE [MIDI].[CTLoad_MIDINewCombo_PossibleBrands] (
    [ID]               INT        IDENTITY (1, 1) NOT NULL,
    [ComboID]          INT        NOT NULL,
    [SuggestedBrandID] SMALLINT   NOT NULL,
    [MatchTypeID]      TINYINT    NOT NULL,
    [BrandProbability] FLOAT (53) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [MIDI].[CTLoad_MIDINewCombo_PossibleBrands]([ComboID] ASC);

