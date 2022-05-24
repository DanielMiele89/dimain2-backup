CREATE TABLE [Staging].[QueryMonitor] (
    [ID]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [LoginName]    NVARCHAR (256) NULL,
    [Duration]     BIGINT         NULL,
    [StartTime]    DATETIME       NULL,
    [EndTime]      DATETIME       NULL,
    [Reads]        BIGINT         NULL,
    [Writes]       BIGINT         NULL,
    [CPU]          INT            NULL,
    [SQLStatement] VARCHAR (8000) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

