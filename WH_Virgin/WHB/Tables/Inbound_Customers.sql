CREATE TABLE [WHB].[Inbound_Customers] (
    [RewardCustomerID]  UNIQUEIDENTIFIER NULL,
    [VirginCustomerID]  INT              NULL,
    [CustomerID]        INT              NULL,
    [Forename]          NVARCHAR (15)    NULL,
    [Surname]           NVARCHAR (30)    NULL,
    [PostCode]          VARCHAR (10)     NULL,
    [DateOfBirth]       DATE             NULL,
    [Gender]            CHAR (1)         NULL,
    [EmailAddress]      NVARCHAR (100)   NULL,
    [BankID]            INT              NULL,
    [MarketableByEmail] CHAR (1)         NULL,
    [MarketableByPush]  CHAR (1)         NULL,
    [MarketableByPhone] CHAR (1)         NULL,
    [MarketableBySms]   CHAR (1)         NULL,
    [RegistrationDate]  DATETIME2 (7)    NULL,
    [ClosedDate]        DATETIME2 (7)    NULL,
    [DeactivatedDate]   DATETIME2 (7)    NULL,
    [LoadDate]          DATETIME2 (7)    NULL,
    [FileName]          NVARCHAR (100)   NULL
);

