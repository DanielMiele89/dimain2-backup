CREATE TABLE [dbo].[testTable] (
    [id]      INT           NULL,
    [id2]     INT           NULL,
    [content] VARCHAR (200) NULL
);


GO
CREATE CLUSTERED INDEX [CLI_id]
    ON [dbo].[testTable]([id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [NCLI_id2]
    ON [dbo].[testTable]([id2] ASC) WITH (FILLFACTOR = 90);

