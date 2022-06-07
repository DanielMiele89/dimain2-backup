CREATE TABLE [dbo].[PRTG_monitor_ReadsWrites] (
    [MeasureDate]          DATETIME     NOT NULL,
    [total_elapsed_time]   BIGINT       NOT NULL,
    [total_worker_time]    BIGINT       NOT NULL,
    [total_logical_reads]  BIGINT       NOT NULL,
    [total_physical_reads] BIGINT       NOT NULL,
    [total_logical_writes] BIGINT       NOT NULL,
    [PrimaryDataReads]     BIGINT       NOT NULL,
    [PrimaryDataWrites]    BIGINT       NOT NULL,
    [PrimaryLogWrites]     BIGINT       NOT NULL,
    [TempDBReads]          BIGINT       NOT NULL,
    [TempDBWrites]         BIGINT       NOT NULL,
    [DBName]               VARCHAR (50) NULL
);

