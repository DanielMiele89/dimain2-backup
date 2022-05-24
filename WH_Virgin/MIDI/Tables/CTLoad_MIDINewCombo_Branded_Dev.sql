CREATE TABLE [MIDI].[CTLoad_MIDINewCombo_Branded_Dev] (
    [ID]             INT            NOT NULL,
    [Narrative]      NVARCHAR (255) NOT NULL,
    [IsHighVariance] BIT            NOT NULL,
    [BrandID]        SMALLINT       NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

