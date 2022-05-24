CREATE TABLE [Staging].[Transactions_DD_20200108] (
    [TransactionID]                  VARCHAR (100)    NULL,
    [BankId]                         VARCHAR (100)    NULL,
    [ExternalCustomerID]             NVARCHAR (100)   NULL,
    [ReversalInd]                    VARCHAR (100)    NULL,
    [ProcessCode]                    VARCHAR (100)    NULL,
    [TransactionDate]                DATE             NULL,
    [OriginatorIdentificationNumber] NVARCHAR (200)   NULL,
    [TransactionTime]                TIME (7)         NULL,
    [Narrative]                      NVARCHAR (200)   NULL,
    [Amount]                         DECIMAL (19, 4)  NULL,
    [CurrencyCode]                   VARCHAR (50)     NULL,
    [PostStatus]                     VARCHAR (50)     NULL,
    [CustomerGUID]                   UNIQUEIDENTIFIER NULL,
    [BankAccountGUID]                UNIQUEIDENTIFIER NULL,
    [ActiveNomineeGUID]              UNIQUEIDENTIFIER NULL,
    [LoadDate]                       DATETIME2 (7)    NULL,
    [FileName]                       NVARCHAR (500)   NULL
);

