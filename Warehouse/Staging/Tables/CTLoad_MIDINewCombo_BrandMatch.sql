CREATE TABLE [Staging].[CTLoad_MIDINewCombo_BrandMatch] (
    [ID]           INT      IDENTITY (1, 1) NOT NULL,
    [ComboID]      INT      NOT NULL,
    [BrandMatchID] INT      NOT NULL,
    [BrandID]      SMALLINT NOT NULL,
    [BrandGroupID] TINYINT  NULL,
    CONSTRAINT [PK_Staging_CTLoad_MIDINewCombo_BrandMatch] PRIMARY KEY CLUSTERED ([ID] ASC)
);

