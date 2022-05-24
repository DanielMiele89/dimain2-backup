CREATE TABLE [Staging].[Redemptions_20200108] (
    [ID]                        BIGINT           IDENTITY (1, 1) NOT NULL,
    [RedemptionTransactionGUID] UNIQUEIDENTIFIER NOT NULL,
    [RedemptionItemID]          BIGINT           NULL,
    [RetailerName]              NVARCHAR (250)   NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NULL,
    [Amount]                    DECIMAL (32, 2)  NULL,
    [RedeemedDate]              DATETIME2 (7)    NULL,
    [MarketingPercentage]       DECIMAL (8, 4)   NULL,
    [Cashback]                  DECIMAL (32, 2)  NULL,
    [Currency]                  VARCHAR (3)      NULL,
    [ConfirmedDate]             DATETIME2 (7)    NULL,
    [CreatedAt]                 DATETIME2 (7)    NULL,
    [UpdatedAt]                 DATETIME2 (7)    NULL,
    [LoadDate]                  DATETIME2 (7)    NOT NULL,
    [FileName]                  NVARCHAR (320)   NOT NULL
);

