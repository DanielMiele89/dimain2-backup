CREATE TABLE [dbo].[PerformanceTest_Data] (
    [id]      INT           NULL,
    [id2]     INT           NULL,
    [content] VARCHAR (200) NULL
);


GO
CREATE CLUSTERED INDEX [CLI_id]
    ON [dbo].[PerformanceTest_Data]([id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [NCLI_id2]
    ON [dbo].[PerformanceTest_Data]([id2] ASC, [content] ASC) WITH (FILLFACTOR = 90);

