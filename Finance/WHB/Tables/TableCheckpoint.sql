CREATE TABLE [WHB].[TableCheckpoint] (
    [CheckpointID]       INT           IDENTITY (1, 1) NOT NULL,
    [SourceTable]        VARCHAR (100) NOT NULL,
    [CheckpointValue]    VARCHAR (500) NULL,
    [CheckpointDateTime] DATETIME      DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_WHB_TableCheckpoint] PRIMARY KEY CLUSTERED ([CheckpointID] ASC) WITH (FILLFACTOR = 90)
);

