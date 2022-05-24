CREATE TABLE [Inbound].[Balances] (
    [CustomerID]            INT            NULL,
    [CashbackPending]       MONEY          NULL,
    [CashbackAvailable]     MONEY          NULL,
    [CashbackLifeTimeValue] MONEY          NULL,
    [LoadDate]              DATETIME2 (7)  NULL,
    [FileName]              NVARCHAR (100) NULL
);




GO
GRANT UPDATE
    ON OBJECT::[Inbound].[Balances] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Inbound].[Balances] TO [crtimport]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Inbound].[Balances] TO [crtimport]
    AS [dbo];

