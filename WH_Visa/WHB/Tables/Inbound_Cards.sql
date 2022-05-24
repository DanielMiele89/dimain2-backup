CREATE TABLE [WHB].[Inbound_Cards] (
    [CardGUID]            UNIQUEIDENTIFIER NULL,
    [AccountGUID]         UNIQUEIDENTIFIER NULL,
    [PrimaryCustomerGUID] UNIQUEIDENTIFIER NULL,
    [BankID]              INT              NULL,
    [LoadDate]            DATETIME2 (7)    NULL,
    [FileName]            NVARCHAR (100)   NULL
);

