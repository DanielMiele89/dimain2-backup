CREATE TABLE [WHB].[SourceCheckpoint] (
    [CheckpointID]     INT          IDENTITY (1, 1) NOT NULL,
    [SourceTypeID]     INT          NOT NULL,
    [CheckpointValue]  VARCHAR (50) NOT NULL,
    [InsertedDateTime] DATETIME     CONSTRAINT [DF_WHB_SourceCheckpoint_InsertedDateTime] DEFAULT (getdate()) NOT NULL,
    [Archived]         BIT          CONSTRAINT [DF_WHB_SourceCheckpoint_Archived] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [FK_WHB_SourceCheckpoint_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);

