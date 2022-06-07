CREATE PROCEDURE [dbo].[PRTG_Level02Alerts]

AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE 
	@C_Usage DECIMAL (18,2),
	@D_Usage DECIMAL (18,2),
	@F_Usage DECIMAL (18,2),
	@TempDB_Usage DECIMAL (18,2),
	@TempDBlog_Usage DECIMAL (18,2),

	@BlockedSpids BIGINT, 
	@MaxDuration BIGINT,
	@ConnectionCount INT,
	@BackupFreeSpace DECIMAL (18,2);

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Volume info for all LUNS that have database files on the current instance (SQL Server 2008 R2 SP1 or greater)  (Query 22) (Volume Info)
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	@C_Usage = SUM(CASE WHEN volume_mount_point = 'C:\' THEN [Usage_GB] ELSE 0 END), 
	@D_Usage = SUM(CASE WHEN volume_mount_point = 'D:\' THEN [Usage_GB] ELSE 0 END), 
	@BackupFreeSpace = SUM(CASE WHEN volume_mount_point = 'D:\' THEN [Available Size (GB)] ELSE 0 END)
FROM (
	SELECT 
		d.volume_mount_point,
		[Available Size (GB)],
		[Usage_GB] = ([Total Size (GB)] - [Available Size (GB)])*100 / [Total Size (GB)]
	FROM (
		SELECT 
			vs.volume_mount_point, 
			[Total Size (GB)] = MAX(vs.total_bytes)/1073741824.0,
			[Available Size (GB)] = MAX(vs.available_bytes)/1073741824.0
		FROM master.sys.master_files AS f 
		CROSS APPLY master.sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs 
		WHERE f.file_id = 1 --OR f.type = 1
		GROUP BY vs.volume_mount_point
	) d
) e


-------------------------------------------------------------------------------------------------------------------------------------------------
-- TempDB % usage
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT @TempDB_Usage = (total_mb - freespace_mb)*100/total_mb
FROM (
	SELECT
		SUM(total_page_count)*8.0/1024 as total_mb,
		SUM(unallocated_extent_page_count)*8.0/1024 as freespace_mb
	FROM tempdb.sys.dm_db_file_space_usage
	WHERE database_id = 2
) d


-------------------------------------------------------------------------------------------------------------------------------------------------
-- TempDBlog % usage
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT @TempDBlog_Usage = LogUsedMB*100/NULLIF(LogSizeMB,0)
 FROM (
	 SELECT 
		LogSizeMB = CONVERT(DEC(9,2), SUM(CASE WHEN counter_name = N'Log File(s) Size (KB)' THEN Cntr_value ELSE 0 END) / 1024.0),
		LogUsedMB = CONVERT(DEC(9,2), SUM(CASE WHEN counter_name = N'Log File(s) Used Size (KB)' THEN Cntr_value ELSE 0 END) / 1024.0)
	 FROM sys.dm_os_performance_counters PC
	 WHERE counter_name IN ('Log File(s) Size (KB)','Log File(s) Used Size (KB)')
		AND instance_name = 'TEMPDB'
 ) d

 
-------------------------------------------------------------------------------------------------------------------------------------------------
-- Blocking, duration
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	@BlockedSpids = COUNT(*), 
	@MaxDuration = MAX(wait_duration)
FROM (
	SELECT 
		wait_duration = MAX(wt.wait_duration_ms)
	FROM sys.dm_tran_locks tl 
	INNER JOIN sys.dm_os_waiting_tasks wt  
		ON tl.lock_owner_address = wt.resource_address
	GROUP BY tl.request_session_id, wt.blocking_session_id
) d;


-------------------------------------------------------------------------------------------------------------------------------------------------
-- Get a count of SQL connections (Query 35) (Connection Counts by IP Address)
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT @ConnectionCount = COUNT(ec.session_id) 
FROM sys.dm_exec_sessions AS es 
INNER JOIN sys.dm_exec_connections AS ec 
	ON es.session_id = ec.session_id;


-------------------------------------------------------------------------------------------------------------------------------------------------
-- Output
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	[C: Used %] = @C_Usage,
	[D: Used %] = @D_Usage,
	[TempDB: Used %] = @TempDB_Usage,
	[TempDBlog: Used %] = @TempDBlog_Usage,
	[BackupFreeSpace] = ISNULL(@BackupFreeSpace,100),

	[Blocked Spids] = @BlockedSpids, 
	[MaxDuration] = ISNULL(@MaxDuration,0),
	[ConnectionCount] = @ConnectionCount,
	[Spare] = 100;


RETURN 0


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PRTG_Level02Alerts] TO [PRTGBuddy]
    AS [dbo];

