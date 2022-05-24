CREATE TABLE [WHB].[Inbound_Cards] (
    [CardID]            UNIQUEIDENTIFIER NULL,
    [AccountID]         UNIQUEIDENTIFIER NULL,
    [PrimaryCustomerID] INT              NULL,
    [BankID]            INT              NULL,
    [LoadDate]          DATETIME2 (7)    NULL,
    [FileName]          NVARCHAR (100)   NULL
);

