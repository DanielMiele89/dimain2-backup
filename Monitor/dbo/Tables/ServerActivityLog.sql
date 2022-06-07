CREATE TABLE [dbo].[ServerActivityLog] (
    [EventStartTime] DATETIME       NOT NULL,
    [EventType]      VARCHAR (50)   NOT NULL,
    [EventEndTime]   DATETIME       NULL,
    [Duration]       BIGINT         NULL,
    [HostName]       VARCHAR (50)   NULL,
    [AppName]        VARCHAR (150)  NULL,
    [LoginName]      VARCHAR (150)  NULL,
    [UserName]       VARCHAR (150)  NULL,
    [DatabaseName]   VARCHAR (50)   NULL,
    [OwnerName]      VARCHAR (25)   NULL,
    [ObjectName]     VARCHAR (250)  NULL,
    [ObjectType]     VARCHAR (50)   NULL,
    [TextData]       VARCHAR (MAX)  NULL,
    [Error]          VARCHAR (2048) NULL,
    [Severity]       TINYINT        NULL,
    [Value]          BIGINT         NULL,
    [FileName]       VARCHAR (256)  NULL
);


GO
CREATE CLUSTERED INDEX [ixc_ServerActivityLog_EventStartTime]
    ON [dbo].[ServerActivityLog]([EventStartTime] ASC);

