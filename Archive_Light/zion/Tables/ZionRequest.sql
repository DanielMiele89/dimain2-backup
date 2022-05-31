CREATE TABLE [zion].[ZionRequest] (
    [ID]                   INT            IDENTITY (1, 1) NOT NULL,
    [Date]                 DATETIME       NOT NULL,
    [FanID]                INT            NULL,
    [ClubID]               INT            NOT NULL,
    [RouteControllerID]    INT            NOT NULL,
    [RouteActionID]        INT            NOT NULL,
    [RouteNumericIdentity] INT            NULL,
    [RouteTextIdentity]    NVARCHAR (250) NULL,
    [IP]                   NVARCHAR (50)  NOT NULL,
    [ElementID]            INT            NULL,
    [SessionID]            NVARCHAR (24)  NOT NULL,
    [IsPostRequest]        BIT            NOT NULL,
    [WebServer]            NVARCHAR (100) NULL,
    [DatabaseServer]       NVARCHAR (100) NULL,
    [DatabaseName]         NVARCHAR (100) NULL,
    [DomainID]             INT            CONSTRAINT [DF_ZionRequest_DomainID] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ZionRequest] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE),
    CONSTRAINT [FK_ZionRequest_RouteActionID] FOREIGN KEY ([RouteActionID]) REFERENCES [zion].[ZionRequestAction] ([ID]),
    CONSTRAINT [FK_ZionRequest_RouteControllerID] FOREIGN KEY ([RouteControllerID]) REFERENCES [zion].[ZionRequestController] ([ID]),
    CONSTRAINT [FK_ZionRequest_ZionRequestDomain] FOREIGN KEY ([DomainID]) REFERENCES [zion].[ZionRequestDomain] ([ID])
);

