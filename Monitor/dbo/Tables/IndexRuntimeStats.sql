CREATE TABLE [dbo].[IndexRuntimeStats] (
    [ReadDate]                     DATETIME       NOT NULL,
    [TableName]                    VARCHAR (25)   NULL,
    [IndexName]                    [sysname]      NULL,
    [fill_factor]                  TINYINT        NULL,
    [avg_fragmentation_in_percent] DECIMAL (5, 3) NULL,
    [page_count]                   BIGINT         NULL
);

