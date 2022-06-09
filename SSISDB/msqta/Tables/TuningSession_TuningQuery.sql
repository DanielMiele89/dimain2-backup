CREATE TABLE [msqta].[TuningSession_TuningQuery] (
    [TuningSessionID] INT    NOT NULL,
    [TuningQueryID]   BIGINT NOT NULL,
    CONSTRAINT [FkTuningSession_TuningQuery_TuningQueryID] FOREIGN KEY ([TuningQueryID]) REFERENCES [msqta].[TuningQuery] ([TuningQueryID]) ON DELETE CASCADE,
    CONSTRAINT [FkTuningSession_TuningQuery_TuningSessionID] FOREIGN KEY ([TuningSessionID]) REFERENCES [msqta].[TuningSession] ([TuningSessionID]) ON DELETE CASCADE
);

