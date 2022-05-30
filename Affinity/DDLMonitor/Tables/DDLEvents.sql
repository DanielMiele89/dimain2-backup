CREATE TABLE [DDLMonitor].[DDLEvents] (
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
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
    [Emailed]      BIT            CONSTRAINT [DF_MI_DDLEvents] DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NIX_EventDate]
    ON [DDLMonitor].[DDLEvents]([EventDate] ASC);

