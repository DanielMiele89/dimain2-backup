CREATE TABLE [dbo].[DDLLog] (
    [ActionTime]   DATETIME      NOT NULL,
    [EventType]    VARCHAR (50)  NOT NULL,
    [HostName]     VARCHAR (50)  NOT NULL,
    [LoginName]    VARCHAR (150) NULL,
    [UserName]     VARCHAR (150) NULL,
    [DatabaseName] VARCHAR (50)  NULL,
    [SchemaName]   VARCHAR (25)  NULL,
    [ObjectName]   VARCHAR (250) NULL,
    [ObjectType]   VARCHAR (50)  NULL,
    [SQLCommand]   VARCHAR (MAX) NULL,
    [ServerDDL]    BIT           CONSTRAINT [DF_DDLLog_ServerDDL] DEFAULT ((0)) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ixc_DDLLog_ActionTime]
    ON [dbo].[DDLLog]([ActionTime] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_DDLLog_EventType]
    ON [dbo].[DDLLog]([EventType] ASC);

