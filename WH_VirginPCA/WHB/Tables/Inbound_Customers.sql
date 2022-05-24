﻿CREATE TABLE [WHB].[Inbound_Customers] (
    [CustomerID]        VARCHAR (250)    NULL,
    [CustomerGUID]      UNIQUEIDENTIFIER NOT NULL,
    [SourceUID]         UNIQUEIDENTIFIER NOT NULL,
    [Forename]          NVARCHAR (255)   NOT NULL,
    [Surname]           NVARCHAR (255)   NOT NULL,
    [PostCode]          NVARCHAR (255)   NULL,
    [DateOfBirth]       DATE             NULL,
    [Gender]            CHAR (1)         NULL,
    [EmailAddress]      NVARCHAR (320)   NOT NULL,
    [MarketableByEmail] BIT              NULL,
    [MarketableByPush]  BIT              NULL,
    [RegistrationDate]  DATETIME2 (7)    NULL,
    [DeactivatedDate]   DATETIME2 (7)    NULL,
    [OptOutDate]        DATETIME2 (7)    NULL,
    [CreatedAt]         DATETIME2 (7)    NOT NULL,
    [UpdatedAt]         DATETIME2 (7)    NOT NULL,
    [ClosedDate]        DATETIME2 (7)    NULL,
    [EmailTracking]     BIT              NULL,
    [CustomerStatusID]  TINYINT          NOT NULL,
    [LoadDate]          DATETIME2 (7)    NOT NULL,
    [FileName]          NVARCHAR (320)   NOT NULL,
    PRIMARY KEY CLUSTERED ([CustomerGUID] ASC)
);

