CREATE TABLE [dbo].[PRTG_Monitor_IOLatency] (
    [MeasureDate]          DATETIME     NOT NULL,
    [type_desc]            VARCHAR (5)  NOT NULL,
    [io_stall_read_ms]     BIGINT       NOT NULL,
    [num_of_reads]         BIGINT       NOT NULL,
    [io_stall_write_ms]    BIGINT       NOT NULL,
    [num_of_writes]        BIGINT       NOT NULL,
    [io_stall]             BIGINT       NOT NULL,
    [num_of_bytes_read]    BIGINT       NOT NULL,
    [num_of_bytes_written] BIGINT       NOT NULL,
    [DBName]               VARCHAR (50) NULL
);

