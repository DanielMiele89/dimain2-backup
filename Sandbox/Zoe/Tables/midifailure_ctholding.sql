CREATE TABLE [Zoe].[midifailure_ctholding] (
    [PartitionID]           INT           NOT NULL,
    [filegroup_name]        [sysname]     NULL,
    [data_compression_desc] NVARCHAR (60) COLLATE Latin1_General_CI_AS_KS_WS NULL,
    [Rows]                  INT           NULL,
    [TranDate]              DATETIME      NULL,
    [rn]                    BIGINT        NULL
);

