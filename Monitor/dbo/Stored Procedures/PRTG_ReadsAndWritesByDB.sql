-- GRANT VIEW SERVER STATE TO PRTGBuddy
-- GRANT VIEW ANY DEFINITION TO PRTGBuddy
-- GRANT EXECUTE ON PRTG_ReadsAndWritesByDB TO PRTGBuddy
-- Master version is PRODUCTION
CREATE PROCEDURE [dbo].[PRTG_ReadsAndWritesByDB]

	@PrimaryDB VARCHAR(50) 

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

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
	[TempDBWrites] [bigint] NOT NULL,
	DBName VARCHAR(50) NOT NULL
) ON [PRIMARY]
*/

/* Reinitialise table after changes
UPDATE [dbo].[PRTG_monitor_ReadsWrites] SET
	[MeasureDate] = GETDATE(),
	[total_elapsed_time] = 0,
	[total_worker_time] = 0,
	[total_logical_reads] = 0,
	[total_physical_reads] = 0,
	[total_logical_writes] = 0,
	[PrimaryDataReads] = 0,
	[PrimaryDataWrites] = 0,
	[PrimaryLogWrites] = 0,
	[TempDBReads] = 0,
	[TempDBWrites] = 0,
	DBName = ''
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


-----------------------------------------------------------------------------------------------
-- Collect the data
-----------------------------------------------------------------------------------------------
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
IF NOT EXISTS (SELECT 1 FROM dbo.PRTG_monitor_ReadsWrites WHERE DBName = @PrimaryDB)
INSERT INTO [dbo].[PRTG_monitor_ReadsWrites] (
	[MeasureDate],
	[total_elapsed_time], [total_worker_time], [total_logical_reads], [total_physical_reads], [total_logical_writes],
	[PrimaryDataReads], [PrimaryDataWrites], [PrimaryLogWrites], [TempDBReads], [TempDBWrites], DBName)
	VALUES (GETDATE(),
	@total_elapsed_time, @total_worker_time, @total_logical_reads, @total_physical_reads, @total_logical_writes,
	@PrimaryDataReads, @PrimaryDataWrites, @PrimaryLogWrites, @TempDBDataReads, @TempDBDataWrites, @PrimaryDB);


-----------------------------------------------------------------------------------------------
-- Compare last run values with this run values
-----------------------------------------------------------------------------------------------
SELECT @Timescale = ISNULL(NULLIF(DATEDIFF(second,MeasureDate,GETDATE()),0),1) FROM dbo.PRTG_monitor_ReadsWrites WHERE DBName = @PrimaryDB

DECLARE @Results TABLE (
	IntervalSec INT,			-- 0
	total_elapsed_time BIGINT,  -- 1
	total_worker_time BIGINT,	-- 2 
	total_logical_reads BIGINT, -- 3 
	total_physical_reads BIGINT,-- 4 
	total_logical_writes BIGINT,-- 5 
	PrimaryDataReads BIGINT,	-- 6 
	PrimaryDataWrites BIGINT,	-- 7
	PrimaryLogWrites BIGINT,	-- 8
	TempDBReads BIGINT,			-- 9
	TempDBWrites BIGINT			-- 10	
	)

UPDATE dbo.PRTG_monitor_ReadsWrites SET
	MeasureDate = GETDATE(), 
	total_elapsed_time = ISNULL(@total_elapsed_time,total_elapsed_time),
	total_worker_time = ISNULL(@total_worker_time,total_worker_time),
	total_logical_reads = ISNULL(@total_logical_reads,total_logical_reads),
	total_physical_reads = ISNULL(@total_physical_reads,total_physical_reads),
	total_logical_writes = ISNULL(@total_logical_writes,total_logical_writes),
	PrimaryDataReads = ISNULL(@PrimaryDataReads,PrimaryDataReads),
	PrimaryDataWrites = ISNULL(@PrimaryDataWrites,PrimaryDataWrites),
	PrimaryLogWrites = ISNULL(@PrimaryLogWrites,PrimaryLogWrites),
	TempDBReads = ISNULL(@TempDBDataReads,TempDBReads),
	TempDBWrites = ISNULL(@TempDBDataWrites,TempDBWrites)
OUTPUT
	@Timescale		AS [IntervalSec], -- 0
	(inserted.total_elapsed_time - deleted.total_elapsed_time)		AS [total_elapsed_time],  -- 1
	(inserted.total_worker_time - deleted.total_worker_time)		AS [total_worker_time], 
	(inserted.total_logical_reads - deleted.total_logical_reads)	AS [total_logical_reads], 
	(inserted.total_physical_reads - deleted.total_physical_reads)	AS [total_physical_reads], 
	(inserted.total_logical_writes - deleted.total_logical_writes)	AS [total_logical_writes], 
	(inserted.PrimaryDataReads - deleted.PrimaryDataReads)			AS [PrimaryDataReads], -- 6 
	(inserted.PrimaryDataWrites - deleted.PrimaryDataWrites)		AS [PrimaryDataWrites], -- 7
	(inserted.PrimaryLogWrites - deleted.PrimaryLogWrites)			AS [PrimaryLogWrites], -- 8
	(inserted.TempDBReads - deleted.TempDBReads)					AS [TempDBReads], -- 9
	(inserted.TempDBWrites - deleted.TempDBWrites)					AS [TempDBWrites] -- 10
INTO @Results
WHERE DBName = @PrimaryDB 


-----------------------------------------------------------------------------------------------
-- Figures can drop due to transaction rollbacks. Unless these are captured,
-- they result in huge swings either side of the zero line in PRTG graphs.
-- Change negative figures to -1 to indicate these events without messing up graphs
-----------------------------------------------------------------------------------------------
SELECT 
	IntervalSec = IntervalSec,			-- 0
	total_elapsed_time = CASE WHEN total_elapsed_time >= 0 THEN total_elapsed_time/IntervalSec ELSE -1 END,		-- 1
	total_worker_time = CASE WHEN total_worker_time >= 0 THEN total_worker_time/IntervalSec ELSE -1 END,		-- 2 
	total_logical_reads = CASE WHEN total_logical_reads >= 0 THEN total_logical_reads/IntervalSec ELSE -1 END,	-- 3 
	total_physical_reads = CASE WHEN total_physical_reads >= 0 THEN total_physical_reads/IntervalSec ELSE -1 END,-- 4 
	total_logical_writes = CASE WHEN total_logical_writes >= 0 THEN total_logical_writes/IntervalSec ELSE -1 END,-- 5 
	PrimaryDataReads = CASE WHEN PrimaryDataReads >= 0 THEN PrimaryDataReads/IntervalSec ELSE -1 END,			-- 6 
	PrimaryDataWrites = CASE WHEN PrimaryDataWrites >= 0 THEN PrimaryDataWrites/IntervalSec ELSE -1 END,		-- 7
	PrimaryLogWrites = CASE WHEN PrimaryLogWrites >= 0 THEN PrimaryLogWrites/IntervalSec ELSE -1 END,			-- 8
	TempDBReads = CASE WHEN TempDBReads >= 0 THEN TempDBReads/IntervalSec ELSE -1 END,							-- 9
	TempDBWrites = CASE WHEN TempDBWrites >= 0 THEN TempDBWrites/IntervalSec ELSE -1 END						-- 10	
FROM @Results r


RETURN 0


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PRTG_ReadsAndWritesByDB] TO [PRTGBuddy]
    AS [dbo];

