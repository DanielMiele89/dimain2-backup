CREATE PROCEDURE [dbo].[PRTG_MonitorIOLatencyByDB] -- DIMAIN
	(@DBName VARCHAR(50))
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-------------------------------------------------------------------------------------------------------
-- Mostly from Paul Randall
-- http://www.sqlskills.com/blogs/paul/how-to-examine-io-subsystem-latencies-from-within-sql-server/
-- GRANT EXECUTE ON PRTG_MonitorIOLatencyByDB TO PRTGBuddy
-- GRANT VIEW ANY DEFINITION TO PRTGBuddy
-------------------------------------------------------------------------------------------------------

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
	@Timescale DECIMAL(7,2)

/*
CREATE TABLE dbo.PRTG_Monitor_IOLatency (
	DBName VARCHAR(50) NOT NULL,
	MeasureDate DATETIME NOT NULL,
	[type_desc] VARCHAR(5) NOT NULL,
	[io_stall_read_ms] BIGINT NOT NULL, 
	[num_of_reads] BIGINT NOT NULL,
	[io_stall_write_ms] BIGINT NOT NULL, 
	[num_of_writes] BIGINT NOT NULL,
	[io_stall] BIGINT NOT NULL, 
	[num_of_bytes_read] BIGINT NOT NULL,
	[num_of_bytes_written] BIGINT NOT NULL
)
*/

IF NOT EXISTS (SELECT 1 FROM dbo.PRTG_Monitor_IOLatency WHERE DBName = @DBName AND [type_desc] = 'ROWS')
	INSERT INTO dbo.PRTG_Monitor_IOLatency (MeasureDate, DBName, [type_desc], [io_stall_read_ms], [num_of_reads], [io_stall_write_ms], [num_of_writes], [io_stall], [num_of_bytes_read], [num_of_bytes_written])
	VALUES (GETDATE(), @DBName, 'ROWS', 0,0,0,0,0,0,0)

IF NOT EXISTS (SELECT 1 FROM dbo.PRTG_Monitor_IOLatency WHERE DBName = @DBName AND [type_desc] = 'LOG')
	INSERT INTO dbo.PRTG_Monitor_IOLatency (MeasureDate, DBName, [type_desc], [io_stall_read_ms], [num_of_reads], [io_stall_write_ms], [num_of_writes], [io_stall], [num_of_bytes_read], [num_of_bytes_written])
	VALUES (GETDATE(), @DBName, 'LOG', 0,0,0,0,0,0,0)

-----------------------------------------------------------------------------------------------------------
-- Capture the stats into a temp table
-----------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#BasicData') IS NOT NULL DROP TABLE #BasicData;
SELECT 
	DBName = @DBName,
	[type_desc] = [type_desc] COLLATE SQL_Latin1_General_CP1_CI_AS,
	[io_stall_read_ms] = ISNULL(SUM([io_stall_read_ms]),0), 
	[num_of_reads] = ISNULL(SUM([num_of_reads]),0),
	[io_stall_write_ms] = ISNULL(SUM([io_stall_write_ms]),0), 
	[num_of_writes] = ISNULL(SUM([num_of_writes]),0),
	[io_stall] = ISNULL(SUM([io_stall]),0), 
	[num_of_bytes_read] = ISNULL(SUM([num_of_bytes_read]),0),
	[num_of_bytes_written] = ISNULL(SUM([num_of_bytes_written]),0)
INTO #BasicData	
FROM sys.dm_io_virtual_file_stats (NULL,NULL) AS [vfs]
JOIN sys.master_files AS [mf]
	ON [vfs].[database_id] = [mf].[database_id]
	AND [vfs].[file_id] = [mf].[file_id]
CROSS APPLY (
	SELECT DB_NAME([vfs].[database_id]) AS [DB]
) x
WHERE x.DB = @DBName
		--AND LEFT ([mf].[physical_name], 2) <> 'C:'
GROUP BY 
	[type_desc]


--SELECT @Timescale = ISNULL(NULLIF(DATEDIFF(second,MeasureDate,GETDATE()),0),1) FROM dbo.PRTG_monitor_ReadsWrites 

DECLARE @Results TABLE (
	[IntervalSec] INT,
	[type_desc] VARCHAR(5) NOT NULL,
	[io_stall_read_ms] BIGINT NOT NULL, 
	[num_of_reads] BIGINT NOT NULL,
	[io_stall_write_ms] BIGINT NOT NULL, 
	[num_of_writes] BIGINT NOT NULL,
	[io_stall] BIGINT NOT NULL, 
	[num_of_bytes_read] BIGINT NOT NULL,
	[num_of_bytes_written] BIGINT NOT NULL
)

UPDATE m SET 
	MeasureDate			= GETDATE(),
	[io_stall_read_ms]	= b.[io_stall_read_ms], 
	[num_of_reads]		= b.[num_of_reads],
	[io_stall_write_ms] = b.[io_stall_write_ms], 
	[num_of_writes]		= b.[num_of_writes],
	[io_stall]			= b.[io_stall], 
	[num_of_bytes_read] = b.[num_of_bytes_read],
	[num_of_bytes_written] = b.[num_of_bytes_written]
OUTPUT
	DATEDIFF(second,deleted.MeasureDate,inserted.MeasureDate)	AS [IntervalSec],
	inserted.[type_desc],
	inserted.[io_stall_read_ms] - deleted.[io_stall_read_ms]	AS [io_stall_read_ms], 
	inserted.[num_of_reads] - deleted.[num_of_reads]			AS [num_of_reads],  
	inserted.[io_stall_write_ms] - deleted.[io_stall_write_ms]	AS [io_stall_write_ms],  
	inserted.[num_of_writes] - deleted.[num_of_writes]			AS [num_of_writes], 
	inserted.[io_stall] - deleted.[io_stall]					AS [io_stall],   
	inserted.[num_of_bytes_read] - deleted.[num_of_bytes_read]	AS [num_of_bytes_read],   
	inserted.[num_of_bytes_written] - deleted.[num_of_bytes_written] AS [num_of_bytes_written]
INTO @Results
FROM dbo.PRTG_Monitor_IOLatency m
INNER JOIN #BasicData b 
	ON b.[type_desc] = m.[type_desc] COLLATE SQL_Latin1_General_CP1_CI_AS
WHERE m.DBName = @DBName


SELECT 
	[IntervalSec]		= MAX([IntervalSec]), 

	[Data_Reads/s]		= MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST([num_of_reads] AS DECIMAL(18,2)) ELSE 0 END),
	[Data_ReadLatency]	= MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST(ISNULL([io_stall_read_ms] / NULLIF([num_of_reads]*1.0,0),0) AS DECIMAL(18,2)) ELSE 0 END),

	[Data_Writes/s]		= MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST([num_of_writes] AS DECIMAL(18,2)) ELSE 0 END),
	[Data_WriteLatency] = MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST(ISNULL([io_stall_write_ms] / NULLIF([num_of_writes]*1.0,0),0) AS DECIMAL(18,2)) ELSE 0 END),

	[Data_AvgBPerRead]	= MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST(ISNULL([num_of_bytes_read] / NULLIF([num_of_reads]*1.0,0),0) AS BIGINT) ELSE 0 END),
	[Data_AvgBPerWrite] = MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST(ISNULL([num_of_bytes_written] / NULLIF([num_of_writes]*1.0,0),0) AS BIGINT) ELSE 0 END),
	
	[Log_ReadLatency]	= MAX(CASE WHEN [type_desc] = 'LOG' THEN CAST(ISNULL([io_stall_read_ms] / NULLIF([num_of_reads]*1.0,0),0) AS DECIMAL(18,2)) ELSE 0 END),
	[Log_WriteLatency]	= MAX(CASE WHEN [type_desc] = 'LOG' THEN CAST(ISNULL([io_stall_write_ms] / NULLIF([num_of_writes]*1.0,0),0) AS DECIMAL(18,2)) ELSE 0 END),

	[Log_AvgBPerRead]	= MAX(CASE WHEN [type_desc] = 'LOG' THEN CAST(ISNULL([num_of_bytes_read] / NULLIF([num_of_reads]*1.0,0),0) AS BIGINT) ELSE 0 END),
	[Log_AvgBPerWrite]	= MAX(CASE WHEN [type_desc] = 'LOG' THEN CAST(ISNULL([num_of_bytes_written] / NULLIF([num_of_writes]*1.0,0),0) AS BIGINT) ELSE 0 END)
	
FROM (
	SELECT 
		[IntervalSec],
		[type_desc],
		[io_stall_read_ms] = [io_stall_read_ms]/([IntervalSec] * 1.00), 
		[num_of_reads] = [num_of_reads]/([IntervalSec] * 1.00),  
		[io_stall_write_ms] = [io_stall_write_ms]/([IntervalSec] * 1.00),  
		[num_of_writes] = [num_of_writes]/([IntervalSec] * 1.00), 
		--[io_stall],   
		[num_of_bytes_read] = [num_of_bytes_read]/([IntervalSec] * 1.00),   
		[num_of_bytes_written] = [num_of_bytes_written]/([IntervalSec] * 1.00)
	FROM @Results
) d 



RETURN 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PRTG_MonitorIOLatencyByDB] TO [PRTGBuddy]
    AS [dbo];

