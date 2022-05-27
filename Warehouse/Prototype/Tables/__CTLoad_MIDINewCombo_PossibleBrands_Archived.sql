CREATE TABLE [Prototype].[__CTLoad_MIDINewCombo_PossibleBrands_Archived] (
    [ID]               INT        IDENTITY (1, 1) NOT NULL,
    [ComboID]          INT        NOT NULL,
    [SuggestedBrandID] SMALLINT   NOT NULL,
    [MatchTypeID]      TINYINT    NOT NULL,
    [BrandProbability] FLOAT (53) NULL
);

