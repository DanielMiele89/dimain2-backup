CREATE PROCEDURE [dbo].[PRTG_MonitorIOLatency]
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-------------------------------------------------------------------------------------------------------
-- Mostly from Paul Randall
-- http://www.sqlskills.com/blogs/paul/how-to-examine-io-subsystem-latencies-from-within-sql-server/
-- GRANT EXECUTE ON PRTG_MonitorIOLatency TO PRTGBuddy
-- GRANT VIEW ANY DEFINITION TO PRTGBuddy
-------------------------------------------------------------------------------------------------------

SELECT 
	[type_desc],
	[io_stall_read_ms] = SUM([io_stall_read_ms]), 
	[num_of_reads] = SUM([num_of_reads]),
	[io_stall_write_ms] = SUM([io_stall_write_ms]), 
	[num_of_writes] = SUM([num_of_writes]),
	[io_stall] = SUM([io_stall]), 
	[num_of_bytes_read] = SUM([num_of_bytes_read]),
	[num_of_bytes_written] = SUM([num_of_bytes_written])
INTO #BasicData	
FROM sys.dm_io_virtual_file_stats (NULL,NULL) AS [vfs]
JOIN sys.master_files AS [mf]
	ON [vfs].[database_id] = [mf].[database_id]
	AND [vfs].[file_id] = [mf].[file_id]
CROSS APPLY (
	SELECT DB_NAME([vfs].[database_id]) AS [DB]
) x
WHERE x.DB NOT IN ('master', 'msdb', 'model')
		AND LEFT ([mf].[physical_name], 2) <> 'C:'
GROUP BY 
	[type_desc]


SELECT 
	[RunDate] = GETDATE(), 

	[Data_ReadLatency]	= MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST(ISNULL([io_stall_read_ms] / NULLIF([num_of_reads],0),0) AS DECIMAL(18,2)) ELSE 0 END),
	[Data_WriteLatency] = MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST(ISNULL([io_stall_write_ms] / NULLIF([num_of_writes],0),0) AS DECIMAL(18,2)) ELSE 0 END),
	[Data_Latency]		= MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST(ISNULL([io_stall] / NULLIF([num_of_reads] + [num_of_writes],0),0) AS DECIMAL(18,2)) ELSE 0 END),
	[Data_AvgBPerRead]	= MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST(ISNULL([num_of_bytes_read] / NULLIF([num_of_reads],0),0) AS DECIMAL(18,2)) ELSE 0 END),
	[Data_AvgBPerWrite] = MAX(CASE WHEN [type_desc] = 'ROWS' THEN CAST(ISNULL([num_of_bytes_written] / NULLIF([num_of_writes],0),0) AS DECIMAL(18,2)) ELSE 0 END),
	
	[Log_ReadLatency]	= MAX(CASE WHEN [type_desc] = 'LOG' THEN CAST(ISNULL([io_stall_read_ms] / NULLIF([num_of_reads],0),0) AS DECIMAL(18,2)) ELSE 0 END),
	[Log_WriteLatency]	= MAX(CASE WHEN [type_desc] = 'LOG' THEN CAST(ISNULL([io_stall_write_ms] / NULLIF([num_of_writes],0),0) AS DECIMAL(18,2)) ELSE 0 END),
	[Log_Latency]		= MAX(CASE WHEN [type_desc] = 'LOG' THEN CAST(ISNULL([io_stall] / NULLIF([num_of_reads] + [num_of_writes],0),0) AS DECIMAL(18,2)) ELSE 0 END),
	[Log_AvgBPerRead]	= MAX(CASE WHEN [type_desc] = 'LOG' THEN CAST(ISNULL([num_of_bytes_read] / NULLIF([num_of_reads],0),0) AS DECIMAL(18,2)) ELSE 0 END),
	[Log_AvgBPerWrite]	= MAX(CASE WHEN [type_desc] = 'LOG' THEN CAST(ISNULL([num_of_bytes_written] / NULLIF([num_of_writes],0),0) AS DECIMAL(18,2)) ELSE 0 END)

FROM #BasicData 

RETURN 0




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PRTG_MonitorIOLatency] TO [PRTGBuddy]
    AS [dbo];

