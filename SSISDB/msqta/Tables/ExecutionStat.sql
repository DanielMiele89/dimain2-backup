CREATE TABLE [msqta].[ExecutionStat] (
    [StatID]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [GroupID]        BIGINT         NOT NULL,
    [StatType]       TINYINT        NOT NULL,
    [IsProfiled]     BIT            NOT NULL,
    [ExecutionCount] BIGINT         NOT NULL,
    [Showplan]       NVARCHAR (MAX) NULL,
    [Stats]          NVARCHAR (MAX) NOT NULL,
    CONSTRAINT [PkExecutionStat_StatID] PRIMARY KEY CLUSTERED ([StatID] ASC),
    CONSTRAINT [FkExecutionStat_GroupID] FOREIGN KEY ([GroupID]) REFERENCES [msqta].[QueryOptionGroup] ([GroupID]) ON DELETE CASCADE
);

