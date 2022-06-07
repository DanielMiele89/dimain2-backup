CREATE TABLE [AWS].[TempLog] (
    [LogDate]    DATETIME       NULL,
    [filelist]   NVARCHAR (MAX) NULL,
    [uploadpath] NVARCHAR (MAX) NULL,
    [servername] [sysname]      NOT NULL
);

