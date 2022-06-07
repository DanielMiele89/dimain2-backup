CREATE PROCEDURE [dbo].[PRTG_Level01Alerts]

AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE 
	@D_Available_SizeGB DECIMAL (18,2), 
	@D_SpaceFreePct DECIMAL (18,2),
	@BlockedSpids BIGINT, 
	@MaxDuration BIGINT,
	@ConnectionCount INT,
	@BackupFreeSpace DECIMAL (18,2);

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Volume info for all LUNS that have database files on the current instance (SQL Server 2008 R2 SP1 or greater)  (Query 22) (Volume Info)
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	@D_Available_SizeGB = [Available Size (GB)],
	@D_SpaceFreePct = ([Available Size (GB)]*100) / [Total Size (GB)]
FROM (
	SELECT 
		vs.volume_mount_point, 
		[Total Size (GB)] = MAX(vs.total_bytes)/1073741824.0,
		[Available Size (GB)] = MAX(vs.available_bytes)/1073741824.0
	FROM master.sys.master_files AS f 
	CROSS APPLY master.sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs 
	WHERE f.file_id = 1 
		AND volume_mount_point = 'D:\'
	GROUP BY vs.volume_mount_point
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
-- 0 / 00:00:00

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Get a count of SQL connections by IP address (Query 35) (Connection Counts by IP Address)
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT @ConnectionCount = COUNT(ec.session_id) 
FROM sys.dm_exec_sessions AS es 
INNER JOIN sys.dm_exec_connections AS ec 
	ON es.session_id = ec.session_id;
-- 1 / 00:00:00

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Output
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	[D: Available Size (GB)] = @D_Available_SizeGB,
	[D: Space Free %] = @D_SpaceFreePct,
	[Blocked Spids] = @BlockedSpids, 
	[MaxDuration] = ISNULL(@MaxDuration,0),
	[ConnectionCount] = @ConnectionCount,
	[BackupFreeSpace] = ISNULL(@BackupFreeSpace,0);



RETURN 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PRTG_Level01Alerts] TO [PRTGBuddy]
    AS [dbo];

