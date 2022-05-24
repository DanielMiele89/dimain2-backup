CREATE TABLE [Inbound].[Cards] (
    [CardGUID]            UNIQUEIDENTIFIER NULL,
    [AccountGUID]         UNIQUEIDENTIFIER NULL,
    [PrimaryCustomerGUID] UNIQUEIDENTIFIER NULL,
    [BankID]              INT              NULL,
    [BinRange]            VARCHAR (255)    NULL,
    [LoadDate]            DATETIME2 (7)    NULL,
    [FileName]            NVARCHAR (100)   NULL
);

