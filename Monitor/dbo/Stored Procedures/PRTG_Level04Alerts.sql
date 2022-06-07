CREATE PROCEDURE [dbo].[PRTG_Level04Alerts] AS 

-- Level 4
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE 
	@Timescale INT,
	@Buffer_cache_hit_ratio BIGINT,
	@Memory_Grants_Pending BIGINT,
	@SQL_Re_Compilations_sec BIGINT,
	@Lock_Timeouts_sec BIGINT,
	@Lock_Wait_Time_ms BIGINT,
	@Full_Scans_sec BIGINT,
	@FreeSpace_Scans_sec BIGINT


IF OBJECT_ID('dbo.PRTG_Monitor_Level04Alerts') IS NULL BEGIN;
	CREATE TABLE [dbo].[PRTG_Monitor_Level04Alerts](
		[MeasureDate] [datetime] NOT NULL,
		[SQL Re-Compilations/sec] [bigint] NOT NULL,
		[Lock Timeouts/sec] [bigint] NOT NULL,
		[Lock Wait Time (ms)] [bigint] NOT NULL,
		[Full Scans/sec] [bigint] NOT NULL,
		[FreeSpace Scans/sec] [bigint] NOT NULL
	) ON [PRIMARY]; 
	INSERT INTO [dbo].[PRTG_Monitor_Level04Alerts] VALUES (GETDATE(),0,0,0,0,0)
END;



SELECT 
	@Buffer_cache_hit_ratio = MAX(CASE WHEN pc.counter_name = 'Buffer cache hit ratio' THEN pc.cntr_value ELSE NULL END),
	@Memory_Grants_Pending = MAX(CASE WHEN pc.counter_name = 'Memory Grants Pending' THEN pc.cntr_value ELSE NULL END),
	@SQL_Re_Compilations_sec = MAX(CASE WHEN pc.counter_name = 'SQL Re-Compilations/sec' THEN pc.cntr_value ELSE NULL END),
	@Lock_Timeouts_sec = MAX(CASE WHEN pc.counter_name = 'Lock Timeouts/sec' THEN pc.cntr_value ELSE NULL END),
	@Lock_Wait_Time_ms = MAX(CASE WHEN pc.counter_name = 'Lock Wait Time (ms)' THEN pc.cntr_value ELSE NULL END),
	@Full_Scans_sec = MAX(CASE WHEN pc.counter_name = 'Full Scans/sec' THEN pc.cntr_value ELSE NULL END),
	@FreeSpace_Scans_sec = MAX(CASE WHEN pc.counter_name = 'FreeSpace Scans/sec' THEN pc.cntr_value ELSE NULL END)
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

SELECT @Timescale = ISNULL(NULLIF(DATEDIFF(second,MeasureDate,GETDATE()),0),1) FROM dbo.PRTG_monitor_ReadsWrites 

DECLARE @Results TABLE (
	[SQL Re-Compilations/sec] BIGINT,
	[Lock Timeouts/sec] BIGINT,
	[Lock Wait Time (ms)] BIGINT,
	[Full Scans/sec] BIGINT,
	[FreeSpace Scans/sec] BIGINT)


UPDATE dbo.PRTG_Monitor_Level04Alerts SET
		[MeasureDate] = GETDATE(),
		[SQL Re-Compilations/sec] = @SQL_Re_Compilations_sec,
		[Lock Timeouts/sec] = @Lock_Timeouts_sec,
		[Lock Wait Time (ms)] = @Lock_Wait_Time_ms,
		[Full Scans/sec] = @Full_Scans_sec,
		[FreeSpace Scans/sec] = @FreeSpace_Scans_sec
OUTPUT 
	inserted.[SQL Re-Compilations/sec]	- deleted.[SQL Re-Compilations/sec] AS [SQL Re-Compilations/sec],
	inserted.[Lock Timeouts/sec]		- deleted.[Lock Timeouts/sec]	AS [Lock Timeouts/sec],
	inserted.[Lock Wait Time (ms)]		- deleted.[Lock Wait Time (ms)] AS [Lock Wait Time (ms)],
	inserted.[Full Scans/sec]			- deleted.[Full Scans/sec]		AS [Full Scans/sec],
	inserted.[FreeSpace Scans/sec]	- deleted.[FreeSpace Scans/sec]		AS [FreeSpace Scans/sec]
INTO @Results

SELECT 
	[Buffer cache hit ratio] = @Buffer_cache_hit_ratio,
	[Memory Grants Pending] = @Memory_Grants_Pending,
	[SQL Re-Compilations/sec],
	[Lock Timeouts/sec],
	[Lock Wait Time (ms)],
	[Full Scans/sec],
	[FreeSpace Scans/sec]
FROM @Results


RETURN 0
