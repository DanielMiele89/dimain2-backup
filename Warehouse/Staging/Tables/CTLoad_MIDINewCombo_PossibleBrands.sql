CREATE TABLE [Staging].[CTLoad_MIDINewCombo_PossibleBrands] (
    [ID]               INT        IDENTITY (1, 1) NOT NULL,
    [ComboID]          INT        NOT NULL,
    [SuggestedBrandID] SMALLINT   NOT NULL,
    [MatchTypeID]      TINYINT    NOT NULL,
    [BrandProbability] FLOAT (53) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CIX_ComboID]
    ON [Staging].[CTLoad_MIDINewCombo_PossibleBrands]([ComboID] ASC) WITH (FILLFACTOR = 70);

