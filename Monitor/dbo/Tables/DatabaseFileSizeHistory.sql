CREATE TABLE [dbo].[DatabaseFileSizeHistory] (
    [LogDate]          DATETIME       CONSTRAINT [DF_DatabaseFileSizeHistory_LogDate] DEFAULT (getdate()) NOT NULL,
    [DatabaseName]     VARCHAR (256)  NULL,
    [LogicalFilename]  VARCHAR (256)  NULL,
    [FileID]           TINYINT        NULL,
    [PhysicalFileName] VARCHAR (2048) NULL,
    [Size]             VARCHAR (64)   NULL,
    [MaxSize]          VARCHAR (24)   NULL,
    [Growth]           VARCHAR (24)   NULL,
    [Usage]            VARCHAR (64)   NULL
);

