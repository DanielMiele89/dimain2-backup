﻿CREATE TABLE [Rory].[Inbound_MatchedTransactions_PCA_20220324_Post] (
    [ID]                    BIGINT           IDENTITY (1, 1) NOT NULL,
    [TransactionGUID]       UNIQUEIDENTIFIER NOT NULL,
    [RetailerGUID]          UNIQUEIDENTIFIER NULL,
    [TransactionDate]       DATETIME2 (7)    NOT NULL,
    [OfferGUID]             UNIQUEIDENTIFIER NOT NULL,
    [OfferRate]             DECIMAL (8, 4)   NULL,
    [CashbackEarned]        MONEY            NULL,
    [CommissionRate]        DECIMAL (8, 4)   NULL,
    [NetAmount]             MONEY            NULL,
    [VatAmount]             MONEY            NULL,
    [GrossAmount]           MONEY            NULL,
    [AccountGUID]           UNIQUEIDENTIFIER NULL,
    [MaskedCardNumber]      VARCHAR (4)      NULL,
    [OIN]                   VARCHAR (100)    NULL,
    [VatRate]               DECIMAL (8, 4)   NULL,
    [Price]                 MONEY            NULL,
    [MerchantID]            VARCHAR (100)    NULL,
    [CustomerGUID]          UNIQUEIDENTIFIER NOT NULL,
    [MatchedDate]           DATETIME2 (7)    NOT NULL,
    [CardGUID]              UNIQUEIDENTIFIER NULL,
    [TransactionTypeID]     INT              NOT NULL,
    [CreatedAt]             DATETIME2 (7)    NOT NULL,
    [NomineeCustomerID]     UNIQUEIDENTIFIER NULL,
    [TransactionExternalId] NVARCHAR (255)   NULL,
    [LoadDate]              DATETIME2 (7)    NOT NULL,
    [FileName]              NVARCHAR (320)   NOT NULL
);

