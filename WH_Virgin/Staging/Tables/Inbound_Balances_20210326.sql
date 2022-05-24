CREATE TABLE [Staging].[Inbound_Balances_20210326] (
    [CustomerID]            INT            NULL,
    [CashbackPending]       MONEY          NULL,
    [CashbackAvailable]     MONEY          NULL,
    [CashbackLifeTimeValue] MONEY          NULL,
    [LoadDate]              DATETIME2 (7)  NULL,
    [FileName]              NVARCHAR (100) NULL
);

