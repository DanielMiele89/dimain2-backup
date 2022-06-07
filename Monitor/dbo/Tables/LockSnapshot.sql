CREATE TABLE [dbo].[LockSnapshot] (
    [spid]         NVARCHAR (10)   NULL,
    [eventinfo]    NVARCHAR (4000) NULL,
    [blockingspid] NVARCHAR (10)   NULL,
    [logdate]      DATETIME        NULL,
    [hostname]     NVARCHAR (128)  NULL,
    [dbname]       NVARCHAR (128)  NULL,
    [status]       NVARCHAR (30)   NULL,
    [cmd]          NVARCHAR (16)   NULL
);


GO
CREATE CLUSTERED INDEX [ix_LockSnapshot_date]
    ON [dbo].[LockSnapshot]([logdate] ASC);

