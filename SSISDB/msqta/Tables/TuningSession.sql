CREATE TABLE [msqta].[TuningSession] (
    [TuningSessionID]      INT            IDENTITY (1, 1) NOT NULL,
    [DatabaseID]           INT            NOT NULL,
    [Name]                 NVARCHAR (300) NULL,
    [Description]          NVARCHAR (400) NULL,
    [Status]               TINYINT        NOT NULL,
    [CreateDate]           DATETIME2 (7)  NOT NULL,
    [LastModifyDate]       DATETIME2 (7)  NOT NULL,
    [BaselineEndDate]      DATETIME2 (7)  NOT NULL,
    [UpgradeDate]          DATETIME2 (7)  NOT NULL,
    [TargetCompatLevel]    INT            NOT NULL,
    [WorkloadDurationDays] INT            NOT NULL,
    CONSTRAINT [PkTuningSession_TuningSessionID] PRIMARY KEY CLUSTERED ([TuningSessionID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IDX_Un_TuningSession_DatabaseID_Name]
    ON [msqta].[TuningSession]([DatabaseID] ASC, [Name] ASC) WHERE ([Name] IS NOT NULL);

