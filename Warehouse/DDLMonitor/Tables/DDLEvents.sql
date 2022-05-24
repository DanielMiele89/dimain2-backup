CREATE TABLE [DDLMonitor].[DDLEvents] (
    [EventDate]    DATETIME       DEFAULT (getdate()) NOT NULL,
    [EventType]    NVARCHAR (64)  NULL,
    [EventDDL]     NVARCHAR (MAX) NULL,
    [EventXML]     XML            NULL,
    [DatabaseName] NVARCHAR (255) NULL,
    [SchemaName]   NVARCHAR (255) NULL,
    [ObjectName]   NVARCHAR (255) NULL,
    [HostName]     VARCHAR (64)   NULL,
    [IPAddress]    VARCHAR (48)   NULL,
    [ProgramName]  NVARCHAR (255) NULL,
    [LoginName]    NVARCHAR (255) NULL,
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
    [Emailed]      BIT            CONSTRAINT [DF_MI_DDLEvents] DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [DDLMonitor].[DDLEvents]([SchemaName] ASC, [Emailed] ASC)
    INCLUDE([ObjectName], [LoginName], [ID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff2]
    ON [DDLMonitor].[DDLEvents]([Emailed] ASC, [LoginName] ASC)
    INCLUDE([SchemaName], [ObjectName], [ID]) WITH (FILLFACTOR = 80);

