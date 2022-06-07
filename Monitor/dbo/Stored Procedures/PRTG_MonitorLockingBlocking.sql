/* LOCKING & BLOCKING
https://msdn.microsoft.com/en-us/library/ms190216(v=sql.110).aspx
http://blogs.msdn.com/b/psssql/archive/2013/09/23/interpreting-the-counter-values-from-sys-dm-os-performance-counters.aspx

Average Wait Time (ms)		Average amount of wait time (in milliseconds) for each lock request that resulted in a wait.
Lock Requests/sec			Number of new locks and lock conversions per second requested from the lock manager.
Lock Timeouts/sec			Number of lock requests per second that timed out, including requests for NOWAIT locks.
Lock Wait Time (ms)			Total wait time (in milliseconds) for locks in the last second.
Lock Waits/sec				Number of lock requests per second that required the caller to wait.
Number of Deadlocks/sec		Number of lock requests per second that resulted in a deadlock.
*/ 
CREATE PROCEDURE [dbo].[PRTG_MonitorLockingBlocking] 

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/*
DROP TABLE dbo.PRTG_monitor_LockingBlocking
CREATE TABLE dbo.PRTG_monitor_LockingBlocking (
	MeasureDate DATETIME NOT NULL,

	TotalLocks BIGINT NOT NULL, 
	AverageWaitTimeMs BIGINT NOT NULL, 
	LockRequestsSec BIGINT NOT NULL, 
	LockTimeoutsSec BIGINT NOT NULL, 
	LockWaitTimeMs BIGINT NOT NULL,
	LockWaitsSec BIGINT NOT NULL, 
	NumberOfDeadlocksSec BIGINT NOT NULL, 
	WaitingTasksCount BIGINT NOT NULL,
	WaitTimeSec BIGINT NOT NULL,
	BlockedSpids BIGINT NOT NULL, 
	MaxDuration BIGINT NOT NULL	
	)

INSERT INTO dbo.PRTG_monitor_LockingBlocking (
	MeasureDate,
	TotalLocks, 
	AverageWaitTimeMs, 
	LockRequestsSec, 
	LockTimeoutsSec, 
	LockWaitTimeMs,
	LockWaitsSec, 
	NumberOfDeadlocksSec, 
	WaitingTasksCount,
	WaitTimeSec,
	BlockedSpids, 
	MaxDuration	) VALUES (
	GETDATE(),
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0
	)

*/

DECLARE
	@TotalLocks BIGINT, 
	@AverageWaitTimeMs BIGINT, 
	@LockRequestsSec BIGINT, 
	@LockTimeoutsSec BIGINT, 
	@LockWaitTimeMs BIGINT,
	@LockWaitsSec BIGINT, 
	@NumberOfDeadlocksSec BIGINT, 
	@WaitingTasksCount BIGINT,
	@WaitTimeSec BIGINT,
	@BlockedSpids BIGINT, 
	@MaxDuration BIGINT,
	@Timescale INT


SELECT @TotalLocks = TotalLocks
FROM (
	SELECT tl.resource_database_id, TotalLocks = COUNT(*)
	FROM sys.dm_tran_locks tl 
	GROUP BY tl.resource_database_id
) d
WHERE d.resource_database_id IN (SELECT d.[dbid] FROM sys.sysdatabases d WHERE d.name IN ('Warehouse','SLC_Report')) -- 

SELECT 
	@AverageWaitTimeMs = MAX(CASE WHEN counter_name = 'Average Wait Time (ms)' THEN cntr_value ELSE NULL END),		-- normal
	@LockRequestsSec = MAX(CASE WHEN counter_name = 'Lock Requests/sec' THEN cntr_value ELSE NULL END),				-- ACCUM
	@LockTimeoutsSec = MAX(CASE WHEN counter_name = 'Lock Timeouts/sec' THEN cntr_value ELSE NULL END),				-- ACCUM
	@LockWaitTimeMs = MAX(CASE WHEN counter_name = 'Lock Wait Time (ms)' THEN cntr_value ELSE NULL END),			-- normal
	@LockWaitsSec = MAX(CASE WHEN counter_name = 'Lock Waits/sec' THEN cntr_value ELSE NULL END),					-- ACCUM
	@NumberOfDeadlocksSec = MAX(CASE WHEN counter_name = 'Number of Deadlocks/sec' THEN cntr_value ELSE NULL END)	-- ACCUM
FROM sys.dm_os_performance_counters 
WHERE [object_name] = 'SQLServer:Locks                                                                                                                 '   
	AND instance_name = '_Total'

SELECT 
	@WaitingTasksCount = SUM(waiting_tasks_count), 
	@WaitTimeSec = SUM(wait_time_ms)/1000
FROM sys.dm_os_wait_stats 
WHERE wait_type LIKE 'LCK_M%'
	AND waiting_tasks_count > 0

SELECT 
	@BlockedSpids = COUNT(*), 
	@MaxDuration = MAX(wait_duration)
FROM (
	SELECT 
		waiter_sid = tl.request_session_id,
		blocker_sid = wt.blocking_session_id,
		wait_duration = MAX(wt.wait_duration_ms)
	FROM sys.dm_tran_locks tl 
	INNER JOIN sys.dm_os_waiting_tasks wt  
		ON tl.lock_owner_address = wt.resource_address
	GROUP BY tl.request_session_id, wt.blocking_session_id
) d


----------------------------------------------------------------------------------------------------------------
SELECT @Timescale = ISNULL(NULLIF(DATEDIFF(second,MeasureDate,GETDATE()),0),1) FROM dbo.PRTG_monitor_ReadsWrites 

DECLARE @Results TABLE (
	[IntervalSec] INT,
	[TotalLocks] BIGINT,
	[AverageWaitTimeMs] BIGINT, 
	[LockRequestsSec] BIGINT,  
	[LockTimeoutsSec] BIGINT,  
	[LockWaitTimeMs] BIGINT, 
	[LockWaitsSec] BIGINT,   
	[NumberOfDeadlocksSec] BIGINT,   
	[WaitingTasksCount] BIGINT, 
	[TaskWaitTimeSec] BIGINT,   
	[BlockedSpids] BIGINT, 
	[MaxSpidBlockDuration] BIGINT
)

UPDATE dbo.PRTG_monitor_LockingBlocking SET 
	MeasureDate			= GETDATE(),
	TotalLocks			= ISNULL(@TotalLocks,0), 
	AverageWaitTimeMs	= ISNULL(@AverageWaitTimeMs,0),  
	LockRequestsSec		= ISNULL(@LockRequestsSec,0),  
	LockTimeoutsSec		= ISNULL(@LockTimeoutsSec,0),  
	LockWaitTimeMs		= ISNULL(@LockWaitTimeMs,0), 
	LockWaitsSec		= ISNULL(@LockWaitsSec,0),  
	NumberOfDeadlocksSec = ISNULL(@NumberOfDeadlocksSec,0),  
	WaitingTasksCount	= ISNULL(@WaitingTasksCount,0), 
	WaitTimeSec			= ISNULL(@WaitTimeSec,0), 
	BlockedSpids		= ISNULL(@BlockedSpids,0),  
	MaxDuration			= ISNULL(@MaxDuration,0)
OUTPUT
	DATEDIFF(second,deleted.MeasureDate,inserted.MeasureDate)	AS [IntervalSec],
	inserted.TotalLocks											AS [TotalLocks],
	inserted.AverageWaitTimeMs - deleted.AverageWaitTimeMs		AS [AverageWaitTimeMs], -- spare, same as LockWaitTimeMs
	inserted.LockRequestsSec - deleted.LockRequestsSec			AS [LockRequestsSec], -- 
	inserted.LockTimeoutsSec - deleted.LockTimeoutsSec			AS [LockTimeoutsSec], -- 
	inserted.LockWaitTimeMs - deleted.LockWaitTimeMs			AS [LockWaitTimeMs], 
	inserted.LockWaitsSec - deleted.LockWaitsSec				AS [LockWaitsSec], --  
	inserted.NumberOfDeadlocksSec - deleted.NumberOfDeadlocksSec AS [NumberOfDeadlocksSec], --  
	inserted.WaitingTasksCount - deleted.WaitingTasksCount		AS [WaitingTasksCount], 
	inserted.WaitTimeSec - deleted.WaitTimeSec					AS [TaskWaitTimeSec], --  
	inserted.BlockedSpids - 0									AS [BlockedSpids], 
	inserted.MaxDuration - deleted.MaxDuration					AS [MaxSpidBlockDuration] 
INTO @Results

SELECT 
	[IntervalSec] = [IntervalSec],
	[TotalLocks],
	[AverageWaitTimeMs] = CASE WHEN AverageWaitTimeMs >= 0 THEN AverageWaitTimeMs/IntervalSec ELSE -1 END, 
	[LockRequestsSec] = CASE WHEN LockRequestsSec >= 0 THEN LockRequestsSec/IntervalSec ELSE -1 END,  
	[LockTimeoutsSec] = CASE WHEN LockTimeoutsSec >= 0 THEN LockTimeoutsSec/IntervalSec ELSE -1 END,  
	[LockWaitTimeMs] = CASE WHEN LockWaitTimeMs >= 0 THEN LockWaitTimeMs/IntervalSec ELSE -1 END, 
	[LockWaitsSec] = CASE WHEN LockWaitsSec >= 0 THEN LockWaitsSec/IntervalSec ELSE -1 END,   
	[NumberOfDeadlocksSec] = CASE WHEN NumberOfDeadlocksSec >= 0 THEN NumberOfDeadlocksSec/IntervalSec ELSE -1 END,   
	[WaitingTasksCount] = CASE WHEN WaitingTasksCount >= 0 THEN WaitingTasksCount/IntervalSec ELSE -1 END, 
	[TaskWaitTimeSec] = CASE WHEN TaskWaitTimeSec >= 0 THEN TaskWaitTimeSec/IntervalSec ELSE -1 END,   
	[BlockedSpids], 
	[MaxSpidBlockDuration] = CASE WHEN MaxSpidBlockDuration >= 0 THEN MaxSpidBlockDuration/IntervalSec ELSE -1 END
FROM @Results


RETURN 0




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PRTG_MonitorLockingBlocking] TO [PRTGBuddy]
    AS [dbo];

