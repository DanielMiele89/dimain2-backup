CREATE TABLE [msqta].[TuningQuery] (
    [TuningQueryID]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [QueryID]                BIGINT         NOT NULL,
    [DatabaseID]             INT            NOT NULL,
    [ParentObjectId]         BIGINT         NULL,
    [QueryHash]              BINARY (8)     NOT NULL,
    [QueryText]              NVARCHAR (MAX) NOT NULL,
    [QueryType]              TINYINT        NOT NULL,
    [IsParametrized]         BIT            NOT NULL,
    [PlanGuide]              NVARCHAR (MAX) NULL,
    [Status]                 TINYINT        NOT NULL,
    [CreateDate]             DATETIME2 (7)  NOT NULL,
    [LastModifyDate]         DATETIME2 (7)  NOT NULL,
    [ProfileCompleteDate]    DATETIME2 (7)  NULL,
    [AnalysisCompleteDate]   DATETIME2 (7)  NULL,
    [ExperimentPendingDate]  DATETIME2 (7)  NULL,
    [ExperimentCompleteDate] DATETIME2 (7)  NULL,
    [DeployedDate]           DATETIME2 (7)  NULL,
    [AbandonedDate]          DATETIME2 (7)  NULL,
    [Parameters]             NVARCHAR (MAX) NULL,
    CONSTRAINT [PkTuningQuery_TuningQueryID] PRIMARY KEY CLUSTERED ([TuningQueryID] ASC)
);

