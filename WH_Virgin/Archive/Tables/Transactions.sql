CREATE TABLE [Archive].[Transactions] (
    [CardID]            UNIQUEIDENTIFIER NOT NULL,
    [MerchantID]        NVARCHAR (50)    NOT NULL,
    [MerchantCountry]   VARCHAR (100)    NOT NULL,
    [MerchantName]      NVARCHAR (200)   NOT NULL,
    [CardholderPresent] VARCHAR (50)     NOT NULL,
    [MerchantClassCode] VARCHAR (50)     NOT NULL,
    [TransactionDate]   DATE             NOT NULL,
    [TransactionTime]   TIME (7)         NOT NULL,
    [Amount]            MONEY            NOT NULL,
    [CurrencyCode]      VARCHAR (50)     NULL,
    [CardInputMode]     VARCHAR (50)     NOT NULL,
    [VirginOfferID]     UNIQUEIDENTIFIER NULL,
    [OfferID]           INT              NULL,
    [CashbackAmount]    MONEY            NULL,
    [CommissionAmount]  MONEY            NULL,
    [LoadDate]          DATETIME2 (7)    NOT NULL,
    [FileName]          NVARCHAR (100)   NOT NULL,
    [FileID]            INT              NOT NULL,
    [RowNum]            INT              NOT NULL
);

