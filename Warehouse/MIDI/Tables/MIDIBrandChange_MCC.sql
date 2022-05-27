CREATE TABLE [MIDI].[MIDIBrandChange_MCC] (
    [ID]             INT      IDENTITY (1, 1) NOT NULL,
    [BrandIDInitial] SMALLINT NOT NULL,
    [MCCID]          SMALLINT NOT NULL,
    [BrandIDChange]  SMALLINT NOT NULL
);

