CREATE TABLE [Inbound].[Transactions] (
    [TransactionID]        VARCHAR (100)    NULL,
    [BankId]               VARCHAR (100)    NULL,
    [ExternalCustomerID]   NVARCHAR (100)   NULL,
    [ExternalCardID]       NVARCHAR (100)   NULL,
    [ReversalInd]          VARCHAR (100)    NULL,
    [ProcessCode]          VARCHAR (100)    NULL,
    [MerchantID]           NVARCHAR (50)    NULL,
    [MerchantCountry]      VARCHAR (100)    NULL,
    [MerchantCategoryCode] VARCHAR (50)     NULL,
    [TransactionDate]      DATE             NULL,
    [TransactionTime]      TIME (7)         NULL,
    [Narrative]            NVARCHAR (200)   NULL,
    [Amount]               DECIMAL (19, 4)  NULL,
    [CurrencyCode]         VARCHAR (50)     NULL,
    [PostStatus]           VARCHAR (50)     NULL,
    [CardInputMode]        VARCHAR (50)     NULL,
    [MaskedPan]            VARCHAR (100)    NULL,
    [CustomerGUID]         UNIQUEIDENTIFIER NULL,
    [BankAccountGUID]      UNIQUEIDENTIFIER NULL,
    [CardGUID]             UNIQUEIDENTIFIER NULL,
    [CreditOrDebit]        VARCHAR (100)    NULL,
    [LoadDate]             DATETIME2 (7)    NULL,
    [FileName]             NVARCHAR (500)   NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FileLoadTanID]
    ON [Inbound].[Transactions]([LoadDate] ASC, [FileName] ASC, [TransactionID] ASC) WITH (FILLFACTOR = 70);

