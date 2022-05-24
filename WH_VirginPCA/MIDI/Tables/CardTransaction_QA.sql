CREATE TABLE [MIDI].[CardTransaction_QA] (
    [ID]             INT      IDENTITY (1, 1) NOT NULL,
    [FileID]         INT      NOT NULL,
    [FileCount]      INT      NOT NULL,
    [MatchedCount]   INT      NOT NULL,
    [UnmatchedCount] INT      NOT NULL,
    [NoCINCount]     INT      NOT NULL,
    [PositiveCount]  INT      NOT NULL,
    [QADate]         DATETIME CONSTRAINT [DF_MIDI_CardTransaction_QA_V2] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_CardTransactionQA_V2] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

