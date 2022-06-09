CREATE TYPE [msqta].[TuningSessionType] AS TABLE (
    [TuningSessionID]      INT            NULL,
    [DatabaseName]         [sysname]      NOT NULL,
    [Name]                 NVARCHAR (300) NULL,
    [Description]          NVARCHAR (400) NULL,
    [Status]               TINYINT        NOT NULL,
    [CreateDate]           DATETIME2 (7)  NOT NULL,
    [LastModifyDate]       DATETIME2 (7)  NOT NULL,
    [BaselineEndDate]      DATETIME2 (7)  NOT NULL,
    [UpgradeDate]          DATETIME2 (7)  NOT NULL,
    [TargetCompatLevel]    INT            NOT NULL,
    [WorkloadDurationDays] INT            NOT NULL);

