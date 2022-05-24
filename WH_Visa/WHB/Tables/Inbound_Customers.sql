CREATE TABLE [WHB].[Inbound_Customers] (
    [CustomerGUID]      UNIQUEIDENTIFIER NULL,
    [VirginCustomerID]  INT              NULL,
    [CustomerID]        INT              NULL,
    [Forename]          VARCHAR (100)    NULL,
    [Surname]           VARCHAR (100)    NULL,
    [PostCode]          VARCHAR (100)    NULL,
    [DateOfBirth]       DATE             NULL,
    [Gender]            CHAR (1)         NULL,
    [EmailAddress]      NVARCHAR (100)   NULL,
    [BankID]            INT              NULL,
    [MarketableByEmail] CHAR (1)         NULL,
    [EmailTracking]     CHAR (1)         NULL,
    [MarketableByPush]  CHAR (1)         NULL,
    [RegistrationDate]  DATETIME2 (7)    NULL,
    [ClosedDate]        DATETIME2 (7)    NULL,
    [OptedOutDate]      DATETIME2 (7)    NULL,
    [DeactivatedDate]   DATETIME2 (7)    NULL,
    [LoadDate]          DATETIME2 (7)    NULL,
    [FileName]          NVARCHAR (100)   NULL
);

