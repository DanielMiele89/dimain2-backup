CREATE TABLE [WHB].[Inbound_Balances] (
    [CustomerGUID]          UNIQUEIDENTIFIER NULL,
    [CashbackPending]       MONEY            NULL,
    [CashbackAvailable]     MONEY            NULL,
    [CashbackLifeTimeValue] MONEY            NULL,
    [LoadDate]              DATETIME2 (7)    NULL,
    [FileName]              NVARCHAR (100)   NULL
);

