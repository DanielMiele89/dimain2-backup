CREATE TABLE [Relational].[WebLogins] (
    [fanid]     INT            NOT NULL,
    [trackdate] DATETIME       NOT NULL,
    [fandata]   NVARCHAR (200) NULL
);


GO
CREATE CLUSTERED INDEX [cx_Trackdate]
    ON [Relational].[WebLogins]([trackdate] ASC, [fanid] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

