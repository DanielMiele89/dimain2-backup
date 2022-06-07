CREATE PROCEDURE [PRTG].[Level01Alerts]

AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE 
	@D_Total_SizeGB DECIMAL (18,2), 
	@D_SpaceFreePct DECIMAL (18,2),
	@BlockedSpids BIGINT, 
	@MaxDuration BIGINT,
	@ConnectionCount INT,
	@BackupFreeSpace DECIMAL (18,2);

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Volume info for all LUNS that have database files on the current instance (SQL Server 2008 R2 SP1 or greater)  (Query 22) (Volume Info)
-------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#LocalVolumeInfo') IS NOT NULL DROP TABLE #LocalVolumeInfo;
CREATE TABLE #LocalVolumeInfo
	(volume_mount_point VARCHAR(3), 
	file_system_type VARCHAR(20), 
	logical_volume_name VARCHAR(20), 
	[Total Size (GB)] DECIMAL(18,2),
	[Available Size (GB)] DECIMAL(18,2),  
	[Space Free %] DECIMAL(18,2)
	)
INSERT INTO #LocalVolumeInfo
EXEC master.dbo.sp_LocalVolumeInfo;

SELECT 
	@D_Total_SizeGB = [Total Size (GB)], 
	@D_SpaceFreePct = [Space Free %] 
FROM #LocalVolumeInfo 
WHERE volume_mount_point = 'D:\';

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
-- Get a count of SQL connections by IP address (Query 35) (Connection Counts by IP Address)
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT @ConnectionCount = COUNT(ec.session_id) 
FROM sys.dm_exec_sessions AS es 
INNER JOIN sys.dm_exec_connections AS ec 
	ON es.session_id = ec.session_id;

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Output
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	[D: Total Size (GB)] = @D_Total_SizeGB,
	[D: Space Free %] = @D_SpaceFreePct,
	[Blocked Spids] = @BlockedSpids, 
	[MaxDuration] = ISNULL(@MaxDuration,0),
	[ConnectionCount] = @ConnectionCount,
	[BackupFreeSpace] = ISNULL(@BackupFreeSpace,0);


	--------------------------------------------
/*
SELECT          physical_device_name,
                backup_start_date,
                backup_finish_date,
                BackupSizeGB = CAST(backup_size/(1024.0*1024.0*1024.0) AS DECIMAL(18,2))
FROM msdb.dbo.backupset b
JOIN msdb.dbo.backupmediafamily m ON b.media_set_id = m.media_set_id
--WHERE database_name = 'Test'
ORDER BY backup_finish_date DESC

-- '\\192.168.5.5\DBBackups\prodfullbackups\SLC_backup_2016_10_29_003001_7030496.bak'
*/

--EXECUTE ('EXEC master.dbo.sp_LocalVolumeInfo') AT DB5

RETURN 0

