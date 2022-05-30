CREATE TABLE [Processing].[MIDTupleMatching] (
    [TempProxyMIDTupleID]   BINARY (32) NOT NULL,
    [ProxyMIDTupleID]       BINARY (32) NOT NULL,
    [FileDate]              DATE        NOT NULL,
    [ConsumerCombinationID] INT         NOT NULL,
    CONSTRAINT [pk_Processing_midimatching] PRIMARY KEY CLUSTERED ([TempProxyMIDTupleID] ASC)
);

