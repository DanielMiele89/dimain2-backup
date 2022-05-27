CREATE PROCEDURE PRTG_Level04Alerts AS 

-- Level 4
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH FirstPass AS (
	SELECT 
		[Buffer cache hit ratio] = MAX(CASE WHEN pc.counter_name = 'Buffer cache hit ratio' THEN pc.cntr_value ELSE NULL END),
		[Memory Grants Pending] = MAX(CASE WHEN pc.counter_name = 'Memory Grants Pending' THEN pc.cntr_value ELSE NULL END),
		[SQL Re-Compilations/sec] = MAX(CASE WHEN pc.counter_name = 'SQL Re-Compilations/sec' THEN pc.cntr_value ELSE NULL END),
		[Lock Timeouts/sec] = MAX(CASE WHEN pc.counter_name = 'Lock Timeouts/sec' THEN pc.cntr_value ELSE NULL END),
		[Lock Wait Time (ms)] = MAX(CASE WHEN pc.counter_name = 'Lock Wait Time (ms)' THEN pc.cntr_value ELSE NULL END),
		[Full Scans/sec] = MAX(CASE WHEN pc.counter_name = 'Full Scans/sec' THEN pc.cntr_value ELSE NULL END),
		[FreeSpace Scans/sec] = MAX(CASE WHEN pc.counter_name = 'FreeSpace Scans/sec' THEN pc.cntr_value ELSE NULL END)
	FROM sys.dm_os_performance_counters pc
	INNER JOIN (
		   SELECT * FROM (VALUES 
				  (N'SQLServer:Buffer Manager',N'Buffer Cache hit ratio'), -- absolute value
				  (N'SQLServer:Memory Manager',N'Memory Grants pending'), -- absolute value
				  (N'SQLServer:SQL Statistics',N'SQL Re-Compilations/sec'), -- goes up 
				  (N'SQLServer:Locks',N'Lock timeouts/sec'), -- goes up
				  (N'SQLServer:Locks',N'Lock Wait Time (ms)'), -- goes up
				  (N'SQLServer:Access Methods',N'Full scans/sec'), -- goes up
				  (N'SQLServer:Access Methods',N'Freespace scans/sec') -- goes up
		   ) d ([object_name], counter_name)
	) x
	ON pc.[object_name] = x.[object_name]
		  AND pc.counter_name = x.counter_name
	WHERE x.counter_name NOT IN ('Lock Timeouts/sec','Lock Wait Time (ms)') OR instance_name = '_Total'
)
SELECT *
FROM FirstPass


RETURN 0
