CREATE TABLE [Staging].[Inbound_Redemptions_20211124] (
    [ID]                        BIGINT           IDENTITY (1, 1) NOT NULL,
    [RedemptionTransactionGUID] UNIQUEIDENTIFIER NOT NULL,
    [RedemptionItemID]          BIGINT           NULL,
    [BankID]                    INT              NULL,
    [RetailerName]              NVARCHAR (250)   NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NULL,
    [Amount]                    MONEY            NULL,
    [RedeemedDate]              DATETIME2 (7)    NULL,
    [MarketingPercentage]       DECIMAL (8, 4)   NULL,
    [Cashback]                  MONEY            NULL,
    [Currency]                  VARCHAR (3)      NULL,
    [ConfirmedDate]             DATETIME2 (7)    NULL,
    [CreatedAt]                 DATETIME2 (7)    NULL,
    [UpdatedAt]                 DATETIME2 (7)    NULL,
    [LoadDate]                  DATETIME2 (7)    NOT NULL,
    [FileName]                  NVARCHAR (320)   NOT NULL
);

