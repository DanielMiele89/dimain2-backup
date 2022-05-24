CREATE TABLE [Staging].[MatchedTransaction_RemovedDupes_20210902] (
    [TransactionTypeID] INT              NULL,
    [TransactionGUID]   UNIQUEIDENTIFIER NULL,
    [CustomerGUID]      UNIQUEIDENTIFIER NULL,
    [CardGUID]          UNIQUEIDENTIFIER NULL,
    [MaskedCardNumber]  VARCHAR (100)    NULL,
    [MerchantID]        VARCHAR (100)    NULL,
    [Price]             MONEY            NULL,
    [TransactionDate]   DATETIME2 (7)    NULL,
    [RetailerGUID]      UNIQUEIDENTIFIER NULL,
    [OfferGUID]         UNIQUEIDENTIFIER NULL,
    [OfferRate]         DECIMAL (8, 4)   NULL,
    [CashbackEarned]    MONEY            NULL,
    [CommissionRate]    DECIMAL (8, 4)   NULL,
    [NetAmount]         MONEY            NULL,
    [VatRate]           DECIMAL (8, 4)   NULL,
    [VatAmount]         MONEY            NULL,
    [GrossAmount]       MONEY            NULL,
    [MatchedDate]       DATETIME2 (7)    NULL,
    [LoadDate]          DATETIME2 (7)    NULL,
    [FileName]          NVARCHAR (100)   NULL
);

