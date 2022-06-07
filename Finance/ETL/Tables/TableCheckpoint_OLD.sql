CREATE TABLE [ETL].[TableCheckpoint_OLD] (
    [CheckpointID]       INT      IDENTITY (1, 1) NOT NULL,
    [CheckpointTypeID]   INT      NOT NULL,
    [CheckpointValue1]   INT      NULL,
    [CheckpointValue2]   INT      NULL,
    [CheckpointDateTime] DATETIME DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_ETL_TableCheckpoint_OLD] PRIMARY KEY CLUSTERED ([CheckpointID] ASC),
    CONSTRAINT [FK_ETL_TableCheckpoint_CheckpointType_OLD] FOREIGN KEY ([CheckpointTypeID]) REFERENCES [ETL].[TableCheckpointType_OLD] ([CheckpointTypeID])
);

