﻿CREATE TABLE [Staging].[Inbound_Transactions_20211124] (
    [CardGUID]                  UNIQUEIDENTIFIER NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NULL,
    [MerchantID]                NVARCHAR (50)    NULL,
    [MerchantCountry]           VARCHAR (100)    NULL,
    [MerchantName]              NVARCHAR (200)   NULL,
    [MerchantAcquirerBin]       VARCHAR (200)    NULL,
    [CardholderPresent]         VARCHAR (50)     NULL,
    [MerchantCategoryCode]      VARCHAR (50)     NULL,
    [TransactionDate]           DATE             NULL,
    [TransactionTime]           TIME (7)         NULL,
    [Amount]                    DECIMAL (19, 4)  NULL,
    [CurrencyCode]              VARCHAR (50)     NULL,
    [CardInputMode]             VARCHAR (50)     NULL,
    [LoadDate]                  DATETIME2 (7)    NULL,
    [FileName]                  NVARCHAR (500)   NULL,
    [TransactionID]             VARCHAR (100)    NULL,
    [MerchantCity]              VARCHAR (50)     NULL,
    [MerchantState]             VARCHAR (50)     NULL,
    [MerchantPostalCode]        VARCHAR (50)     NULL,
    [VisaStoreName]             VARCHAR (200)    NULL,
    [VisaMerchantName]          VARCHAR (100)    NULL,
    [TokenTransactionIndicator] VARCHAR (50)     NULL,
    [TokenRequesterId]          VARCHAR (50)     NULL
);

