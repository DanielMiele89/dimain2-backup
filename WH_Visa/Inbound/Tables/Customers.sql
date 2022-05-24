CREATE TABLE [Inbound].[Customers] (
    [CustomerGUID]      UNIQUEIDENTIFIER NULL,
    [CustomerID]        INT              NULL,
    [SourceUID]         UNIQUEIDENTIFIER NULL,
    [Forename]          NVARCHAR (255)   NULL,
    [Surname]           NVARCHAR (255)   NULL,
    [EmailAddress]      NVARCHAR (255)   NULL,
    [PostCode]          VARCHAR (255)    NULL,
    [DateOfBirth]       DATE             NULL,
    [Gender]            CHAR (1)         NULL,
    [BankID]            INT              NULL,
    [MarketableByEmail] BIT              NULL,
    [MarketableByPush]  BIT              NULL,
    [RegistrationDate]  DATETIME2 (7)    NULL,
    [ClosedDate]        DATETIME2 (7)    NULL,
    [OptOutDate]        DATETIME2 (7)    NULL,
    [DeactivatedDate]   DATETIME2 (7)    NULL,
    [CreatedAt]         DATETIME2 (7)    NULL,
    [UpdatedAt]         DATETIME2 (7)    NULL,
    [LoadDate]          DATETIME2 (7)    NULL,
    [FileName]          NVARCHAR (100)   NULL,
    [EmailTracking]     BIT              NULL
);

