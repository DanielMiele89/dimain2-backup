CREATE TABLE [Staging].[CTLoad_MIDINewCombo_IncorrectlyBranded] (
    [RunDate]           DATE          NULL,
    [MatchType]         TINYINT       NULL,
    [OriginatorID]      VARCHAR (11)  NOT NULL,
    [MID]               VARCHAR (50)  NOT NULL,
    [SuggestedBrandID]  SMALLINT      NULL,
    [BrandID]           SMALLINT      NOT NULL,
    [Narrative]         VARCHAR (50)  NOT NULL,
    [Narrative_Cleaned] VARCHAR (250) NULL,
    [LocationCountry]   VARCHAR (3)   NOT NULL,
    [BrandReviewed]     BIT           NULL
);

