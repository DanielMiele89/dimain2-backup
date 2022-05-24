CREATE TABLE [Archive].[Transactions_RemovedDuplicates] (
    [CardID]            UNIQUEIDENTIFIER NULL,
    [MerchantID]        NVARCHAR (50)    NULL,
    [MerchantCountry]   VARCHAR (100)    NULL,
    [MerchantName]      NVARCHAR (200)   NULL,
    [CardholderPresent] VARCHAR (50)     NULL,
    [MerchantClassCode] VARCHAR (50)     NULL,
    [TransactionDate]   DATE             NULL,
    [TransactionTime]   TIME (7)         NULL,
    [Amount]            MONEY            NULL,
    [CurrencyCode]      VARCHAR (50)     NULL,
    [CardInputMode]     VARCHAR (50)     NULL,
    [VirginOfferID]     UNIQUEIDENTIFIER NULL,
    [OfferID]           INT              NULL,
    [CashbackAmount]    MONEY            NULL,
    [CommissionAmount]  MONEY            NULL,
    [LoadDate]          DATETIME2 (7)    NULL,
    [FileName]          NVARCHAR (100)   NULL
);

