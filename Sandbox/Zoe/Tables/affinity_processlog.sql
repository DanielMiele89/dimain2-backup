CREATE TABLE [Zoe].[affinity_processlog] (
    [FileID]              INT         NOT NULL,
    [FileType]            VARCHAR (6) NOT NULL,
    [ReceivedDate]        DATETIME    NOT NULL,
    [MIDIProcessDate]     DATETIME    NULL,
    [AffinityProcessDate] DATETIME    NULL,
    [RowCount]            INT         NULL,
    [DupesCount]          INT         NULL
);

