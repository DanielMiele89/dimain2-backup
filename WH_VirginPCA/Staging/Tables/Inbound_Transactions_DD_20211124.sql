CREATE TABLE [Staging].[Inbound_Transactions_DD_20211124] (
    [AccountGUID]     UNIQUEIDENTIFIER NULL,
    [CustomerGUID]    UNIQUEIDENTIFIER NULL,
    [OIN]             NVARCHAR (50)    NULL,
    [MerchantName]    NVARCHAR (200)   NULL,
    [TransactionDate] DATE             NULL,
    [TransactionTime] TIME (7)         NULL,
    [Amount]          DECIMAL (19, 4)  NULL,
    [CurrencyCode]    VARCHAR (50)     NULL,
    [TransactionID]   VARCHAR (100)    NULL,
    [LoadDate]        DATETIME2 (7)    NULL,
    [FileName]        NVARCHAR (500)   NULL
);

