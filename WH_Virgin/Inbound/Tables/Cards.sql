CREATE TABLE [Inbound].[Cards] (
    [CardID]            UNIQUEIDENTIFIER NULL,
    [AccountID]         UNIQUEIDENTIFIER NULL,
    [PrimaryCustomerID] INT              NULL,
    [BankID]            INT              NULL,
    [LoadDate]          DATETIME2 (7)    NULL,
    [FileName]          NVARCHAR (100)   NULL
);




GO
GRANT UPDATE
    ON OBJECT::[Inbound].[Cards] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Inbound].[Cards] TO [crtimport]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Inbound].[Cards] TO [crtimport]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Inbound].[Cards] TO [crtimport]
    AS [dbo];

