CREATE TABLE [Staging].[Inbound_Redemptions_20210110] (
    [RedemptionTransactionGUID] UNIQUEIDENTIFIER NOT NULL,
    [RedemptionItemID]          INT              NOT NULL,
    [BankID]                    VARCHAR (250)    NULL,
    [RetailerName]              VARCHAR (250)    NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NULL,
    [Amount]                    DECIMAL (8, 4)   NULL,
    [RedeemedDate]              DATETIME2 (7)    NULL,
    [MarketingPercentage]       DECIMAL (8, 4)   NULL,
    [Cashback]                  DECIMAL (8, 4)   NULL,
    [Currency]                  VARCHAR (3)      NULL,
    [ConfirmedDate]             DATETIME2 (7)    NULL,
    [CreatedAt]                 DATETIME2 (7)    NULL,
    [UpdatedAt]                 DATETIME2 (7)    NULL,
    [LoadDate]                  DATETIME2 (7)    NULL,
    [FileName]                  NVARCHAR (100)   NULL
);

