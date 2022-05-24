-- =============================================
-- Author:		JEA
-- Create date: 14/12/2012
-- Description:	Gathers performance information
-- concentrated on the Warehouse database
-- CJM 20161116 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
-- =============================================
CREATE PROCEDURE [Staging].[WarehousePerformanceMonitor_Insert]
	
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- CJM 20161116

    --time value variables
Declare @FullScansSecValue1 bigint, @FullScansSecValue2 bigint, @FullScansSec float
	, @IndexSearchesSecValue1 bigint, @IndexSearchesSecValue2 bigint, @IndexSearchesSec float
	, @PageSplitsSecValue1 bigint, @PageSplitsSecValue2 bigint, @PageSplitsSec float
	, @WorkFilesCreatedSecValue1 bigint, @WorkFilesCreatedSecValue2 bigint, @WorkFilesCreatedSec float
	, @WorkTablesCreatedSecValue1 bigint, @WorkTablesCreatedSecValue2 bigint, @WorkTablesCreatedSec float
	, @LogBytesFlushedSecValue1 bigint, @LogBytesFlushedSecValue2 bigint, @LogBytesFlushedSec float
	, @LogFlushWaitsSecValue1 bigint, @LogFlushWaitsSecValue2 bigint, @LogFlushWaitsSec float
	, @LogFlushesSecValue1 bigint, @LogFlushesSecValue2 bigint, @LogFlushesSec float
	, @FreeListStallsSecValue1 bigint, @FreeListStallsSecValue2 bigint, @FreeListStallsSec float
	, @LazyWritesSecValue1 bigint, @LazyWritesSecValue2 bigint, @LazyWritesSec float
	, @CheckpointPagesSecValue1 bigint, @CheckpointPagesSecValue2 bigint, @CheckpointPagesSec float
	, @PageLookupsSecValue1 bigint, @PageLookupsSecValue2 bigint, @PageLookupsSec float
	, @PageReadsSecValue1 bigint, @PageReadsSecValue2 bigint, @PageReadsSec float
	, @PageWritesSecValue1 bigint, @PageWritesSecValue2 bigint, @PageWritesSec float
	, @ReadAheadsSecValue1 bigint, @ReadAheadsSecValue2 bigint, @ReadAheadsSec float
	, @BatchRequestsSecValue1 bigint, @BatchRequestsSecValue2 bigint, @BatchRequestsSec float
	, @SQLCompilationsSecValue1 bigint, @SQLCompilationsSecValue2 bigint, @SQLCompilationsSec float
	, @SQLRecompilationsSecValue1 bigint, @SQLRecompilationsSecValue2 bigint, @SQLRecompilationsSec float
	, @AttentionRateSecValue1 bigint, @AttentionRateSecValue2 bigint, @AttentionRateSec float
	, @LockWaitsSecValue1 bigint, @LockWaitsSecValue2 bigint, @LockWaitsSec float
	, @LockRequestsSecValue1 bigint, @LockRequestsSecValue2 bigint, @LockRequestsSec float
	, @LockTimeoutsSecValue1 bigint, @LockTimeoutsSecValue2 bigint, @LockTimeoutsSec float
	, @NumberOfDeadlocksSecValue1 bigint, @NumberOfDeadlocksSecValue2 bigint, @NumberOfDeadlocksSec float
	, @TableLockEscalationsSecValue1 bigint, @TableLockEscalationsSecValue2 bigint, @TableLockEscalationsSec float
	, @Duration int

--absolute value variables
Declare @DataFileSizeKB bigint, @LogFileSizeKB bigint, @LogFileUsedSizeKB bigint, @LogFlushWaitTime bigint, @LogGrowths bigint
	, @LogShrinks bigint, @PercentLogUsed bigint, @PageLifeExpectancy bigint, @DatabasePages bigint, @TargetPages bigint
	, @TotalPages bigint, @FreePages bigint, @StolenPagesSec bigint, @TotalServerMemoryKB bigint, @TargetServerMemoryKB bigint
	, @ActiveCursors bigint, @LongestRunningTransactionTime bigint

--base ratio variables
Declare @BufferCacheHitRatioMain float, @BufferCacheHitRatioBase float, @BufferCacheHitRatio float
Declare @AverageLatchWaitTimeMain float, @AverageLatchWaitTimeBase float, @AverageLatchWaitTimeMS float
Declare @AverageLockWaitTimeMain float, @AverageLockWaitTimeBase float, @AverageLockWaitTimeMS float
Declare @WorktablesFromCacheRatioMain float, @WorktablesFromCacheRatioBase float, @WorktablesFromCacheRatio float


SET @Duration = 10

SELECT @FullScansSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Full Scans/sec', '')
SELECT @IndexSearchesSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Index Searches/sec', '')
SELECT @PageSplitsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Page Splits/sec', '')
SELECT @WorkFilesCreatedSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Workfiles Created/sec', '')
SELECT @WorkTablesCreatedSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Worktables Created/sec', '')
SELECT @LogBytesFlushedSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log Bytes Flushed/sec', 'Warehouse')
SELECT @LogFlushWaitsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log Flush Waits/sec', 'Warehouse')
SELECT @LogFlushesSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log Flushes/sec', 'Warehouse')
SELECT @FreeListStallsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Free list stalls/sec', '')
SELECT @LazyWritesSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Lazy writes/sec', '')
SELECT @CheckpointPagesSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Checkpoint pages/sec', '')
SELECT @PageLookupsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Page lookups/sec', '')
SELECT @PageReadsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Page reads/sec', '')
SELECT @PageWritesSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Page writes/sec', '')
SELECT @ReadAheadsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Readahead pages/sec', '')
SELECT @BatchRequestsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:SQL Statistics', 'Batch Requests/sec', '')
SELECT @SQLCompilationsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:SQL Statistics', 'SQL Compilations/sec', '')
SELECT @SQLRecompilationsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:SQL Statistics', 'SQL Re-Compilations/sec', '')
SELECT @AttentionRateSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:SQL Statistics', 'SQL Attention rate', '')
SELECT @LockWaitsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Lock Waits/sec', '_Total')
SELECT @LockRequestsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Lock Requests/sec', '_Total')
SELECT @LockTimeoutsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Lock Timeouts/sec', '_Total')
SELECT @NumberOfDeadlocksSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Number of Deadlocks/sec', '_Total')
SELECT @TableLockEscalationsSecValue1 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Table Lock Escalations/sec', '')

WAITFOR DELAY @Duration

SELECT @FullScansSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Full Scans/sec', '')
SELECT @IndexSearchesSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Index Searches/sec', '')
SELECT @PageSplitsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Page Splits/sec', '')
SELECT @WorkFilesCreatedSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Workfiles Created/sec', '')
SELECT @WorkTablesCreatedSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Worktables Created/sec', '')
SELECT @LogBytesFlushedSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log Bytes Flushed/sec', 'Warehouse')
SELECT @LogFlushWaitsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log Flush Waits/sec', 'Warehouse')
SELECT @LogFlushesSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log Flushes/sec', 'Warehouse')
SELECT @FreeListStallsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Free list stalls/sec', '')
SELECT @LazyWritesSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Lazy writes/sec', '')
SELECT @CheckpointPagesSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Checkpoint pages/sec', '')
SELECT @PageLookupsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Page lookups/sec', '')
SELECT @PageReadsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Page reads/sec', '')
SELECT @PageWritesSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Page writes/sec', '')
SELECT @ReadAheadsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Readahead pages/sec', '')
SELECT @BatchRequestsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:SQL Statistics', 'Batch Requests/sec', '')
SELECT @SQLCompilationsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:SQL Statistics', 'SQL Compilations/sec', '')
SELECT @SQLRecompilationsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:SQL Statistics', 'SQL Re-Compilations/sec', '')
SELECT @AttentionRateSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:SQL Statistics', 'SQL Attention rate', '')
SELECT @LockWaitsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Lock Waits/sec', '_Total')
SELECT @LockRequestsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Lock Requests/sec', '_Total')
SELECT @LockTimeoutsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Lock Timeouts/sec', '_Total')
SELECT @NumberOfDeadlocksSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Number of Deadlocks/sec', '_Total')
SELECT @TableLockEscalationsSecValue2 = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Table Lock Escalations/sec', '')

IF @Duration = 0
BEGIN
	SET @FullScansSec = 0
	SET @IndexSearchesSec = 0
	SET @PageSplitsSec = 0
	SET @WorkFilesCreatedSec = 0
	SET @WorkTablesCreatedSec = 0
	SET @LogBytesFlushedSec = 0
	SET @LogFlushWaitsSec = 0
	SET @LogFlushesSec = 0
	SET @FreeListStallsSec = 0
	SET @LazyWritesSec = 0
	SET @CheckpointPagesSec = 0
	SET @PageLookupsSec = 0
	SET @PageReadsSec = 0
	SET @PageWritesSec = 0
	SET @ReadAheadsSec = 0
	SET @BatchRequestsSec = 0
	SET @SQLCompilationsSec = 0
	SET @SQLRecompilationsSec = 0
	SET @AttentionRateSec = 0
	SET @LockWaitsSec = 0
	SET @LockRequestsSec = 0
	SET @LockTimeoutsSec = 0
	SET @NumberOfDeadlocksSec = 0
	SET @TableLockEscalationsSec = 0
END
ELSE
BEGIN

	SELECT @FullScansSec = CAST(@FullScansSecValue2 - @FullScansSecValue1 AS FLOAT) / @Duration
	SELECT @IndexSearchesSec = CAST(@IndexSearchesSecValue2 - @IndexSearchesSecValue1 AS FLOAT) / @Duration
	SELECT @PageSplitsSec = CAST(@PageSplitsSecValue2 - @PageSplitsSecValue1 AS FLOAT) / @Duration
	SELECT @WorkFilesCreatedSec = CAST(@WorkFilesCreatedSecValue2 - @WorkFilesCreatedSecValue1 AS FLOAT) / @Duration
	SELECT @WorkTablesCreatedSec = CAST(@WorkTablesCreatedSecValue2 - @WorkTablesCreatedSecValue1 AS FLOAT) / @Duration
	SELECT @LogBytesFlushedSec = CAST(@LogBytesFlushedSecValue2 - @LogBytesFlushedSecValue1 AS FLOAT) / @Duration
	SELECT @LogFlushWaitsSec = CAST(@LogFlushWaitsSecValue2 - @LogFlushWaitsSecValue1 AS FLOAT) / @Duration
	SELECT @LogFlushesSec = CAST(@LogFlushesSecValue2 - @LogFlushesSecValue1 AS FLOAT) / @Duration
	SELECT @FreeListStallsSec = CAST(@FreeListStallsSecValue2 - @FreeListStallsSecValue1 AS FLOAT) / @Duration
	SELECT @LazyWritesSec = CAST(@LazyWritesSecValue2 - @LazyWritesSecValue1 AS FLOAT) / @Duration
	SELECT @CheckpointPagesSec = CAST(@CheckpointPagesSecValue2 - @CheckpointPagesSecValue1 AS FLOAT) / @Duration
	SELECT @PageLookupsSec = CAST(@PageLookupsSecValue2 - @PageLookupsSecValue1 AS FLOAT) / @Duration
	SELECT @PageReadsSec = CAST(@PageReadsSecValue2 - @PageReadsSecValue1 AS FLOAT) / @Duration
	SELECT @PageWritesSec = CAST(@PageWritesSecValue2 - @PageWritesSecValue1 AS FLOAT) / @Duration
	SELECT @ReadAheadsSec = CAST(@ReadAheadsSecValue2 - @ReadAheadsSecValue1 AS FLOAT) / @Duration
	SELECT @BatchRequestsSec = CAST(@BatchRequestsSecValue2 - @BatchRequestsSecValue1 AS FLOAT) / @Duration
	SELECT @SQLCompilationsSec = CAST(@SQLCompilationsSecValue2 - @SQLCompilationsSecValue1 AS FLOAT) / @Duration
	SELECT @SQLRecompilationsSec = CAST(@SQLRecompilationsSecValue2 - @SQLRecompilationsSecValue1 AS FLOAT) / @Duration
	SELECT @AttentionRateSec = CAST(@AttentionRateSecValue2 - @AttentionRateSecValue1 AS FLOAT) / @Duration
	SELECT @LockWaitsSec = CAST(@LockWaitsSecValue2 - @LockWaitsSecValue1 AS FLOAT) / @Duration
	SELECT @LockRequestsSec = CAST(@LockRequestsSecValue2 - @LockRequestsSecValue1 AS FLOAT) / @Duration
	SELECT @LockTimeoutsSec = CAST(@LockTimeoutsSecValue2 - @LockTimeoutsSecValue1 AS FLOAT) / @Duration
	SELECT @NumberOfDeadlocksSec = CAST(@NumberOfDeadlocksSecValue2 - @NumberOfDeadlocksSecValue1 AS FLOAT) / @Duration
	SELECT @TableLockEscalationsSec = CAST(@TableLockEscalationsSecValue2 - @TableLockEscalationsSecValue1 AS FLOAT) / @Duration
END

SELECT @DataFileSizeKB = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Data File(s) Size (KB)', 'Warehouse')
SELECT @LogFileSizeKB = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log File(s) Size (KB)', 'Warehouse')
SELECT @LogFileUsedSizeKB = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log File(s) Used Size (KB)', 'Warehouse')
SELECT @LogFlushWaitTime = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log Flush Wait Time', 'Warehouse')
--SELECT @LogGrowths = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log Growths', 'Warehouse')
--SELECT @LogShrinks = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Log Shrinks', 'Warehouse')
--SELECT @PercentLogUsed = Staging.GetSQLPerfCounterValue('SQLServer:Databases', 'Percent Log Used', 'Warehouse')
SELECT @PageLifeExpectancy = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Page life expectancy', '')
SELECT @DatabasePages = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Database pages', '')
--SELECT @TargetPages = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Target pages', '')
--SELECT @TotalPages = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Total pages', '')
SELECT @FreePages = Staging.GetSQLPerfCounterValue('SQLServer:Memory Manager', 'Free Memory (KB)', '')/8
SELECT @StolenPagesSec = Staging.GetSQLPerfCounterValue('SQLServer:Memory Manager', 'Stolen Server Memory (KB)', '')/8
--SELECT @TotalServerMemoryKB = Staging.GetSQLPerfCounterValue('SQLServer:Memory Manager', 'Total Server Memory (KB)', '')
--SELECT @TargetServerMemoryKB = Staging.GetSQLPerfCounterValue('SQLServer:Memory Manager', 'Target Server Memory (KB)', '')
--SELECT @ActiveCursors = Staging.GetSQLPerfCounterValue('SQLServer:Cursor Manager by Type', 'Active cursors', '_Total')
--SELECT @LongestRunningTransactionTime = Staging.GetSQLPerfCounterValue('SQLServer:Transactions', 'Longest Transaction Running Time', '')

SELECT @BufferCacheHitRatioMain = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Buffer cache hit ratio', '')
SELECT @BufferCacheHitRatioBase = Staging.GetSQLPerfCounterValue('SQLServer:Buffer Manager', 'Buffer cache hit ratio base', '')
SELECT @AverageLatchWaitTimeMain = Staging.GetSQLPerfCounterValue('SQLServer:Latches', 'Average Latch Wait Time (ms)', '')
SELECT @AverageLatchWaitTimeBase = Staging.GetSQLPerfCounterValue('SQLServer:Latches', 'Average Latch Wait Time Base', '')
SELECT @AverageLockWaitTimeMain = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Average Wait Time (ms)', '_Total')
SELECT @AverageLockWaitTimeBase = Staging.GetSQLPerfCounterValue('SQLServer:Locks', 'Average Wait Time Base', '_Total')
SELECT @WorktablesFromCacheRatioMain = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Worktables From Cache Ratio', '')
SELECT @WorktablesFromCacheRatioBase = Staging.GetSQLPerfCounterValue('SQLServer:Access Methods', 'Worktables From Cache Base', '')

SELECT @BufferCacheHitRatio = case when @BufferCacheHitRatioBase = 0 then 0 else (@BufferCacheHitRatioMain*100)/@BufferCacheHitRatioBase end
SELECT @AverageLatchWaitTimeMS = case when @AverageLatchWaitTimeBase = 0 then 0 else @AverageLatchWaitTimeMain/@AverageLatchWaitTimeBase end
SELECT @AverageLockWaitTimeMS = case when @AverageLockWaitTimeBase = 0 then 0 else @AverageLockWaitTimeMain/@AverageLockWaitTimeBase end
SELECT @WorktablesFromCacheRatio = case when @WorktablesFromCacheRatioBase = 0 then 0 else @WorktablesFromCacheRatioMain/@WorktablesFromCacheRatioBase end

INSERT INTO Staging.WarehousePerformanceMonitor (
FullScansSec
, IndexSearchesSec
, PageSplitsSec
, WorkFilesCreatedSec
, WorkTablesCreatedSec
, LogBytesFlushedSec
, LogFlushWaitsSec
, LogFlushesSec
, FreeListStallsSec
, LazyWritesSec
, CheckpointPagesSec
, PageLookupsSec
, PageReadsSec
, PageWritesSec
, ReadAheadsSec
, BatchRequestsSec
, SQLCompilationsSec
, SQLRecompilationsSec
, AttentionRateSec
, LockWaitsSec
, LockRequestsSec
, LockTimeoutsSec
, NumberOfDeadlocksSec
, TableLockEscalationsSec
, DataFileSizeKB
, LogFileSizeKB
, LogFileUsedSizeKB
, LogFlushWaitTime
--, LogGrowths
--, LogShrinks
--, PercentLogUsed
, PageLifeExpectancy
, DatabasePages
--, TargetPages
--, TotalPages
, FreePages
, StolenPagesSec
--, TotalServerMemoryKB
--, TargetServerMemoryKB
--, ActiveCursors
--, LongestRunningTransactionTime
, BufferCacheHitRatio
, AverageLatchWaitTimeMS
, AverageLockWaitTimeMS
, WorkTablesFromCacheRatio)
VALUES(
@FullScansSec
, @IndexSearchesSec
, @PageSplitsSec
, @WorkFilesCreatedSec
, @WorkTablesCreatedSec
, @LogBytesFlushedSec
, @LogFlushWaitsSec
, @LogFlushesSec
, @FreeListStallsSec
, @LazyWritesSec
, @CheckpointPagesSec
, @PageLookupsSec
, @PageReadsSec
, @PageWritesSec
, @ReadAheadsSec
, @BatchRequestsSec
, @SQLCompilationsSec
, @SQLRecompilationsSec
, @AttentionRateSec
, @LockWaitsSec
, @LockRequestsSec
, @LockTimeoutsSec
, @NumberOfDeadlocksSec
, @TableLockEscalationsSec
, @DataFileSizeKB
, @LogFileSizeKB
, @LogFileUsedSizeKB
, @LogFlushWaitTime
--, @LogGrowths
--, @LogShrinks
--, @PercentLogUsed
, @PageLifeExpectancy
, @DatabasePages
--, @TargetPages
--, @TotalPages
, @FreePages
, @StolenPagesSec
--, @TotalServerMemoryKB
--, @TargetServerMemoryKB
--, @ActiveCursors
--, @LongestRunningTransactionTime
, @BufferCacheHitRatio
, @AverageLatchWaitTimeMS
, @AverageLockWaitTimeMS
, @WorkTablesFromCacheRatio)

END
