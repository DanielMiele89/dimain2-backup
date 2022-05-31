CREATE TABLE [PatrickM].[ZionActionFanTemp] (
    [ID]               INT            NOT NULL,
    [FanID]            INT            NULL,
    [ZionActionID]     INT            NOT NULL,
    [Date]             DATETIME2 (3)  NOT NULL,
    [IP]               NVARCHAR (50)  NOT NULL,
    [ElementID]        INT            NULL,
    [SessionID]        NVARCHAR (24)  NOT NULL,
    [WebServer]        NVARCHAR (100) NULL,
    [DatabaseServer]   NVARCHAR (100) NULL,
    [DatabaseName]     NVARCHAR (100) NULL,
    [Email]            NVARCHAR (100) NULL,
    [MaskedCardNumber] VARCHAR (19)   NULL
);

