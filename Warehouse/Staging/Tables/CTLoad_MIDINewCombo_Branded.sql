CREATE TABLE [Staging].[CTLoad_MIDINewCombo_Branded] (
    [ID]             INT          NOT NULL,
    [Narrative]      VARCHAR (50) NOT NULL,
    [IsHighVariance] BIT          NOT NULL,
    [BrandID]        SMALLINT     NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

