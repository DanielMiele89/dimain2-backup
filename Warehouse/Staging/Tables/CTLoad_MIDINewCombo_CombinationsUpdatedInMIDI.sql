CREATE TABLE [Staging].[CTLoad_MIDINewCombo_CombinationsUpdatedInMIDI] (
    [ID]                        INT           IDENTITY (1, 1) NOT NULL,
    [MatchType]                 TINYINT       NULL,
    [MID]                       VARCHAR (50)  NULL,
    [OriginatorID]              VARCHAR (11)  NULL,
    [MCCID]                     INT           NULL,
    [LocationCountry]           VARCHAR (3)   NULL,
    [Narrative]                 VARCHAR (50)  NULL,
    [OriginalNarrative]         VARCHAR (50)  NULL,
    [OriginalNarrative_Cleaned] VARCHAR (250) NULL,
    [BrandID]                   SMALLINT      NULL,
    [SuggestedBrandID]          SMALLINT      NULL,
    [EntryReviewed]             BIT           NULL,
    [RunDate]                   DATE          NULL
);

