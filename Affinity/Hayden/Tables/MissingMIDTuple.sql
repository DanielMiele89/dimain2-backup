CREATE TABLE [Hayden].[MissingMIDTuple] (
    [MIDTupleID]      BINARY (32)   NULL,
    [Narrative]       VARCHAR (10)  NULL,
    [EncodedMID]      VARCHAR (MAX) NULL,
    [DecodedMID]      VARCHAR (50)  NULL,
    [LocationCountry] VARCHAR (10)  NULL,
    [MCCID]           VARCHAR (5)   NULL
);

