-- GRANT VIEW SERVER STATE TO PRTGBuddy
-- GRANT VIEW ANY DEFINITION TO PRTGBuddy
-- GRANT EXECUTE ON PRTG_ReadsAndWrites TO PRTGBuddy
-- Master version is PRODUCTION
CREATE PROCEDURE dbo.PRTG_ReadsAndWrites

-- @PrimaryDB VARCHAR(50) = 'Warehouse'

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @PrimaryDB VARCHAR(50) = 'Warehouse'

/*
CREATE TABLE [dbo].[PRTG_monitor_ReadsWrites](
	[MeasureDate] [datetime] NOT NULL,
	[total_elapsed_time] [bigint] NOT NULL,
	[total_worker_time] [bigint] NOT NULL,
	[total_logical_reads] [bigint] NOT NULL,
	[total_physical_reads] [bigint] NOT NULL,
	[total_logical_writes] [bigint] NOT NULL,
	[PrimaryDataReads] [bigint] NOT NULL,
	[PrimaryDataWrites] [bigint] NOT NULL,
	[PrimaryLogWrites] [bigint] NOT NULL,
	[TempDBReads] [bigint] NOT NULL,
	[TempDBWrites] [bigint] NOT NULL
) ON [PRIMARY]
*/

DECLARE
	@Timescale INT,
	@PrimaryDataReads BIGINT,
	@PrimaryDataWrites BIGINT,
	@PrimaryLogWrites BIGINT,
	@TempDBDataReads BIGINT,
	@TempDBDataWrites BIGINT,
	@total_elapsed_time BIGINT,
	@total_worker_time BIGINT,
	@total_logical_reads BIGINT,
	@total_physical_reads BIGINT,
	@total_logical_writes BIGINT

;WITH Firstpass AS (
	SELECT 
		x.db, 
		mf.[type_desc], 
		num_of_bytes_read = SUM(vfs.num_of_bytes_read), 
		num_of_bytes_written = SUM(vfs.num_of_bytes_written) 	 
	FROM sys.dm_io_virtual_file_stats(NULL,NULL) vfs
	JOIN sys.master_files AS [mf]
		ON [vfs].[database_id] = [mf].[database_id]
		AND [vfs].[file_id] = [mf].[file_id]
	CROSS APPLY (
		SELECT DB_NAME ([vfs].[database_id]) AS [DB]
	) x
	WHERE [DB] = @PrimaryDB 
		OR ([DB] = 'tempdb' AND mf.[type_desc] = 'ROWS')
	GROUP BY x.db, 
		mf.[type_desc]
)
SELECT 
	@PrimaryDataReads = MAX(CASE WHEN db = @PrimaryDB AND [type_desc] = 'ROWS' THEN num_of_bytes_read ELSE 0 END),
	@PrimaryDataWrites = MAX(CASE WHEN db = @PrimaryDB AND [type_desc] = 'ROWS' THEN num_of_bytes_written ELSE 0 END),
	@PrimaryLogWrites = MAX(CASE WHEN db = @PrimaryDB AND [type_desc] = 'LOG' THEN num_of_bytes_written ELSE 0 END),
	@TempDBDataReads = MAX(CASE WHEN db = 'tempdb' AND [type_desc] = 'ROWS' THEN num_of_bytes_read ELSE 0 END),
	@TempDBDataWrites = MAX(CASE WHEN db = 'tempdb' AND [type_desc] = 'ROWS' THEN num_of_bytes_written ELSE 0 END)
FROM Firstpass;

-- this doesn't always respond
SELECT
	@total_elapsed_time = SUM(total_elapsed_time),
	@total_worker_time = SUM(total_worker_time),
	@total_logical_reads = SUM(total_logical_reads),
	@total_physical_reads = SUM(total_physical_reads),
	@total_logical_writes = SUM(total_logical_writes)
FROM sys.dm_exec_query_Stats;

-----------------------------------------------------------------------------------------------
-- If this is the first run then load the table with current values
-----------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.PRTG_monitor_ReadsWrites)
INSERT INTO [dbo].[PRTG_monitor_ReadsWrites] (
	[MeasureDate],
	[total_elapsed_time], [total_worker_time], [total_logical_reads], [total_physical_reads], [total_logical_writes],
	[PrimaryDataReads], [PrimaryDataWrites], [PrimaryLogWrites], [TempDBReads], [TempDBWrites])
	VALUES (GETDATE(),
	@total_elapsed_time, @total_worker_time, @total_logical_reads, @total_physical_reads, @total_logical_writes,
	@PrimaryDataReads, @PrimaryDataWrites, @PrimaryLogWrites, @TempDBDataReads, @TempDBDataWrites);

-----------------------------------------------------------------------------------------------
-- Compare last run values with this run values
-----------------------------------------------------------------------------------------------
SELECT 
	@Timescale = x.Timescale,
	@total_elapsed_time = CASE WHEN @total_elapsed_time >= total_elapsed_time THEN @total_elapsed_time ELSE total_elapsed_time END, 
	@total_worker_time = CASE WHEN @total_worker_time >= total_worker_time THEN @total_worker_time ELSE total_worker_time END, 
	@total_logical_reads = CASE WHEN @total_logical_reads >= total_logical_reads THEN @total_logical_reads ELSE total_logical_reads END,
	@total_physical_reads = CASE WHEN @total_physical_reads >= total_physical_reads THEN @total_physical_reads ELSE total_physical_reads END,
	@total_logical_writes = CASE WHEN @total_logical_writes >= total_logical_writes THEN @total_logical_writes ELSE total_logical_writes END,
	@PrimaryDataReads = CASE WHEN @PrimaryDataReads >= PrimaryDataReads THEN @PrimaryDataReads ELSE PrimaryDataReads END,
	@PrimaryDataWrites = CASE WHEN @PrimaryDataWrites >= PrimaryDataWrites THEN @PrimaryDataWrites ELSE PrimaryDataWrites END,
	@PrimaryLogWrites = CASE WHEN @PrimaryLogWrites >= PrimaryLogWrites THEN @PrimaryLogWrites ELSE PrimaryLogWrites END,
	@TempDBDataReads = CASE WHEN @TempDBDataReads >= TempDBReads THEN @TempDBDataReads ELSE TempDBReads END,
	@TempDBDataWrites = CASE WHEN @TempDBDataWrites >= TempDBWrites THEN @TempDBDataWrites ELSE TempDBWrites END 
FROM dbo.PRTG_monitor_ReadsWrites
CROSS APPLY (
	SELECT Timescale = ISNULL(NULLIF(DATEDIFF(second,MeasureDate,GETDATE()),0),1)
) x

UPDATE dbo.PRTG_monitor_ReadsWrites SET
	MeasureDate = GETDATE(), 
	total_elapsed_time = @total_elapsed_time,
	total_worker_time = @total_worker_time,
	total_logical_reads = @total_logical_reads,
	total_physical_reads = @total_physical_reads,
	total_logical_writes = @total_logical_writes,
	PrimaryDataReads = @PrimaryDataReads,
	PrimaryDataWrites = @PrimaryDataWrites,
	PrimaryLogWrites = @PrimaryLogWrites,
	TempDBReads = @TempDBDataReads,
	TempDBWrites = @TempDBDataWrites
OUTPUT
	@Timescale		AS [IntervalSec], -- 0
	(inserted.total_elapsed_time - deleted.total_elapsed_time) / @Timescale		AS [total_elapsed_time],  -- 1
	(inserted.total_worker_time - deleted.total_worker_time) / @Timescale		AS [total_worker_time], 
	(inserted.total_logical_reads - deleted.total_logical_reads) / @Timescale	AS [total_logical_reads], 
	(inserted.total_physical_reads - deleted.total_physical_reads) / @Timescale	AS [total_physical_reads], 
	(inserted.total_logical_writes - deleted.total_logical_writes) / @Timescale	AS [total_logical_writes], 
	(inserted.PrimaryDataReads - deleted.PrimaryDataReads) / @Timescale			AS [PrimaryDataReads], -- 6 
	(inserted.PrimaryDataWrites - deleted.PrimaryDataWrites) / @Timescale		AS [PrimaryDataWrites], -- 7
	(inserted.PrimaryLogWrites - deleted.PrimaryLogWrites) / @Timescale			AS [PrimaryLogWrites], -- 8
	(inserted.TempDBReads - deleted.TempDBReads) / @Timescale					AS [TempDBReads], -- 9
	(inserted.TempDBWrites - deleted.TempDBWrites) / @Timescale					AS [TempDBWrites] -- 10


RETURN 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PRTG_ReadsAndWrites] TO [PRTGBuddy]
    AS [dbo];

