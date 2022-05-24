CREATE TABLE [WHB].[Inbound_Accounts] (
    [CustomerID]          INT              NULL,
    [BankID]              INT              NULL,
    [AccountID]           UNIQUEIDENTIFIER NULL,
    [AccountType]         VARCHAR (100)    NULL,
    [AccountStatus]       VARCHAR (100)    NULL,
    [CashbackNomineeID]   INT              NULL,
    [AccountRelationship] VARCHAR (100)    NULL,
    [LoadDate]            DATETIME2 (7)    NULL,
    [FileName]            NVARCHAR (100)   NULL
);

