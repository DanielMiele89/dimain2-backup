CREATE TABLE [dbo].[ExpensiveWarehouseQueries20161108] (
    [Procname]             NVARCHAR (128) NULL,
    [ExecTimeSeconds]      NUMERIC (8, 1) NULL,
    [Statement_text]       NVARCHAR (MAX) NULL,
    [query_plan]           XML            NULL,
    [last_execution_start] DATETIME       NOT NULL,
    [last_execution_end]   DATETIME       NULL,
    [execution_count]      BIGINT         NOT NULL,
    [s_total_worker_time]  NUMERIC (8, 1) NULL,
    [s_last_worker_time]   NUMERIC (8, 1) NULL,
    [total_physical_reads] BIGINT         NOT NULL,
    [last_physical_reads]  BIGINT         NOT NULL,
    [total_logical_reads]  BIGINT         NOT NULL,
    [last_logical_reads]   BIGINT         NOT NULL,
    [total_logical_writes] BIGINT         NOT NULL,
    [last_logical_writes]  BIGINT         NOT NULL,
    [total_rows]           BIGINT         NOT NULL,
    [last_rows]            BIGINT         NOT NULL
);

