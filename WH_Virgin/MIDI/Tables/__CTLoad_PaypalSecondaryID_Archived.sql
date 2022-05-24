CREATE TABLE [MIDI].[__CTLoad_PaypalSecondaryID_Archived] (
    [FileID]                 INT          NOT NULL,
    [RowNum]                 INT          NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (22) NOT NULL,
    [ConsumerCombinationID]  INT          NOT NULL,
    [SecondaryCombinationID] INT          NULL,
    CONSTRAINT [PK_MIDI_CTLoad_PaypalSecondaryID] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

