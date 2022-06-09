CREATE TYPE [msqta].[ExecutionStatType] AS TABLE (
    [GroupID]        BIGINT         NOT NULL,
    [QueryID]        BIGINT         NOT NULL,
    [DatabaseName]   [sysname]      NOT NULL,
    [StatType]       TINYINT        NOT NULL,
    [IsProfiled]     BIT            NOT NULL,
    [ExecutionCount] BIGINT         NOT NULL,
    [Showplan]       NVARCHAR (MAX) NULL,
    [Stats]          NVARCHAR (MAX) NOT NULL);

