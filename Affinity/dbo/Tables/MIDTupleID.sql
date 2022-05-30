CREATE TABLE [dbo].[MIDTupleID] (
    [ConsumerCombinationID] INT              NOT NULL,
    [ProxyMIDTupleID]       VARBINARY (8000) NULL,
    [ProxyMID]              NVARCHAR (MAX)   NULL,
    [LocationCountry]       VARCHAR (3)      NOT NULL,
    [Narrative]             VARCHAR (50)     NOT NULL,
    [OriginatorID]          VARCHAR (11)     NOT NULL,
    [MCC]                   VARCHAR (4)      NULL,
    [MID]                   VARCHAR (50)     NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [CIX]
    ON [dbo].[MIDTupleID]([ConsumerCombinationID] ASC);

