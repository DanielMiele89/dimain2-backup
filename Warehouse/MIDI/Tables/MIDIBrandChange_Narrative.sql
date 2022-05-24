CREATE TABLE [MIDI].[MIDIBrandChange_Narrative] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [BrandIDInitial] SMALLINT     NOT NULL,
    [Narrative]      VARCHAR (50) NOT NULL,
    [BrandIDChange]  SMALLINT     NOT NULL
);

