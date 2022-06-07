CREATE TABLE [dbo].[PRTG_monitor_LockingBlocking] (
    [MeasureDate]          DATETIME NOT NULL,
    [TotalLocks]           BIGINT   NOT NULL,
    [AverageWaitTimeMs]    BIGINT   NOT NULL,
    [LockRequestsSec]      BIGINT   NOT NULL,
    [LockTimeoutsSec]      BIGINT   NOT NULL,
    [LockWaitTimeMs]       BIGINT   NOT NULL,
    [LockWaitsSec]         BIGINT   NOT NULL,
    [NumberOfDeadlocksSec] BIGINT   NOT NULL,
    [WaitingTasksCount]    BIGINT   NOT NULL,
    [WaitTimeSec]          BIGINT   NOT NULL,
    [BlockedSpids]         BIGINT   NOT NULL,
    [MaxDuration]          BIGINT   NOT NULL
);

