CREATE TABLE [MIDI].[CTLoad_MIDINewCombo_PossibleBrands_Dev] (
    [ID]               INT        IDENTITY (1, 1) NOT NULL,
    [ComboID]          INT        NOT NULL,
    [SuggestedBrandID] SMALLINT   NOT NULL,
    [MatchTypeID]      TINYINT    NOT NULL,
    [BrandProbability] FLOAT (53) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [MIDI].[CTLoad_MIDINewCombo_PossibleBrands_Dev]([ComboID] ASC) WITH (FILLFACTOR = 90);

