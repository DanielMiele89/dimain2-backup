CREATE TABLE [Staging].[Inbound_RedemptionOffers_20211124] (
    [ID]                    BIGINT           IDENTITY (1, 1) NOT NULL,
    [RedemptionOfferGUID]   UNIQUEIDENTIFIER NULL,
    [RedemptionPartnerGUID] UNIQUEIDENTIFIER NULL,
    [BankID]                INT              NULL,
    [RetailerName]          VARCHAR (250)    NULL,
    [Amount]                MONEY            NULL,
    [MarketingPercentage]   DECIMAL (8, 4)   NULL,
    [Currency]              VARCHAR (3)      NULL,
    [WarningThreshold]      INT              NULL,
    [Status]                VARCHAR (50)     NULL,
    [Priority]              INT              NULL,
    [CreatedAt]             DATETIME2 (7)    NULL,
    [UpdatedAt]             DATETIME2 (7)    NULL,
    [LoadDate]              DATETIME2 (7)    NOT NULL,
    [FileName]              NVARCHAR (320)   NOT NULL
);

