CREATE TABLE [Inbound].[Redemptions] (
    [RedemptionTransactionGUID] UNIQUEIDENTIFIER NOT NULL,
    [RedemptionItemID]          INT              NOT NULL,
    [BankID]                    VARCHAR (250)    NULL,
    [RetailerName]              VARCHAR (250)    NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NULL,
    [Amount]                    DECIMAL (32, 2)  NULL,
    [RedeemedDate]              DATETIME2 (7)    NULL,
    [MarketingPercentage]       DECIMAL (8, 4)   NULL,
    [Cashback]                  DECIMAL (32, 2)  NULL,
    [Currency]                  VARCHAR (3)      NULL,
    [ConfirmedDate]             DATETIME2 (7)    NULL,
    [CreatedAt]                 DATETIME2 (7)    NULL,
    [UpdatedAt]                 DATETIME2 (7)    NULL,
    [LoadDate]                  DATETIME2 (7)    NULL,
    [FileName]                  NVARCHAR (100)   NULL
);

