CREATE TABLE [msqta].[QueryOptionGroup] (
    [GroupID]                BIGINT         IDENTITY (1, 1) NOT NULL,
    [TuningQueryID]          BIGINT         NOT NULL,
    [QueryOptions]           NVARCHAR (MAX) NOT NULL,
    [IsVerified]             BIT            NOT NULL,
    [IsDeployed]             BIT            NOT NULL,
    [ValidationCompleteDate] DATETIME2 (7)  NULL,
    CONSTRAINT [PkQueryOptionGroup_GroupID] PRIMARY KEY CLUSTERED ([GroupID] ASC),
    CONSTRAINT [FkQueryOptionGroup_TuningQueryID] FOREIGN KEY ([TuningQueryID]) REFERENCES [msqta].[TuningQuery] ([TuningQueryID]) ON DELETE CASCADE
);

