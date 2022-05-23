CREATE TABLE [zion].[ZionActionFan] (
    [ID]               INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FanID]            INT            NULL,
    [ZionActionID]     INT            NOT NULL,
    [Date]             DATETIME       NOT NULL,
    [IP]               NVARCHAR (50)  NOT NULL,
    [ElementID]        INT            NULL,
    [SessionID]        NVARCHAR (24)  NOT NULL,
    [WebServer]        NVARCHAR (100) NULL,
    [DatabaseServer]   NVARCHAR (100) NULL,
    [DatabaseName]     NVARCHAR (100) NULL,
    [Email]            NVARCHAR (100) NULL,
    [MaskedCardNumber] VARCHAR (19)   NULL,
    CONSTRAINT [PK_ZionActionFan] PRIMARY KEY CLUSTERED ([ID] ASC)
);

