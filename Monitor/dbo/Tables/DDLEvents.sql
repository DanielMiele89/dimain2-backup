CREATE TABLE [dbo].[DDLEvents] (
    [EventDate]    DATETIME       NOT NULL,
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
    [Emailed]      BIT            NOT NULL
);

