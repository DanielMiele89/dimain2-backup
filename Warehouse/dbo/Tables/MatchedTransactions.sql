CREATE TABLE [dbo].[MatchedTransactions] (
    [TransactionTypeID]     INT              NULL,
    [TransactionExternalID] VARCHAR (255)    NULL,
    [TransactionGUID]       UNIQUEIDENTIFIER NULL,
    [CustomerGUID]          UNIQUEIDENTIFIER NULL,
    [CardGUID]              UNIQUEIDENTIFIER NULL,
    [MerchantID]            VARCHAR (100)    NULL,
    [Price]                 MONEY            NULL,
    [TransactionDate]       DATETIME2 (7)    NULL,
    [OfferGUID]             UNIQUEIDENTIFIER NULL,
    [MatchedDate]           DATETIME2 (7)    NULL,
    [MaxID]                 INT              NULL,
    [MinID]                 INT              NULL
);

