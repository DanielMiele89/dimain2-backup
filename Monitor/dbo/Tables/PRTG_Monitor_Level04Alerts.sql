CREATE TABLE [dbo].[PRTG_Monitor_Level04Alerts] (
    [MeasureDate]             DATETIME NOT NULL,
    [SQL Re-Compilations/sec] BIGINT   NOT NULL,
    [Lock Timeouts/sec]       BIGINT   NOT NULL,
    [Lock Wait Time (ms)]     BIGINT   NOT NULL,
    [Full Scans/sec]          BIGINT   NOT NULL,
    [FreeSpace Scans/sec]     BIGINT   NOT NULL
);

