CREATE TABLE [Inbound].[Partner] (
    [ID]                     INT              IDENTITY (1, 1) NOT NULL,
    [RetailerID]             INT              NULL,
    [RetailerGUID]           UNIQUEIDENTIFIER NULL,
    [RetailerName]           VARCHAR (100)    NULL,
    [RetailerRegisteredName] VARCHAR (100)    NOT NULL,
    [PartnerID]              INT              NOT NULL,
    [PartnerName]            VARCHAR (100)    NOT NULL,
    [PartnerRegisteredName]  VARCHAR (100)    NOT NULL,
    [AccountManager]         VARCHAR (50)     NULL,
    [Status]                 SMALLINT         NOT NULL,
    [ShowMaps]               BIT              NOT NULL
);

