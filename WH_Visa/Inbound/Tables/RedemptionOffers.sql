CREATE TABLE [Inbound].[RedemptionOffers] (
    [RedemptionOfferGUID]   UNIQUEIDENTIFIER NULL,
    [RedemptionPartnerGUID] UNIQUEIDENTIFIER NULL,
    [BankID]                VARCHAR (250)    NULL,
    [RetailerName]          VARCHAR (250)    NULL,
    [Amount]                DECIMAL (32, 2)  NULL,
    [MarketingPercentage]   DECIMAL (8, 4)   NULL,
    [Currency]              VARCHAR (3)      NULL,
    [WarningThreshold]      INT              NOT NULL,
    [Status]                VARCHAR (50)     NULL,
    [Priority]              INT              NOT NULL,
    [CreatedAt]             DATETIME2 (7)    NULL,
    [UpdatedAt]             DATETIME2 (7)    NULL,
    [LoadDate]              DATETIME2 (7)    NULL,
    [FileName]              NVARCHAR (100)   NULL
);

