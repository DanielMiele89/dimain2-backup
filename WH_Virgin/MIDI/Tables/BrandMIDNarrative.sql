CREATE TABLE [MIDI].[BrandMIDNarrative] (
    [BrandID]           INT           NULL,
    [MID]               VARCHAR (50)  NULL,
    [Narrative_Pattern] VARCHAR (750) NULL,
    [Choice]            TINYINT       NULL
);


GO
CREATE CLUSTERED INDEX [cx_BMN]
    ON [MIDI].[BrandMIDNarrative]([MID] ASC, [Narrative_Pattern] ASC);

