CREATE TABLE [Staging].[Inbound_RedemptionItems_20210110] (
    [RedemptionItemID]    INT              NOT NULL,
    [RedemptionOfferGUID] UNIQUEIDENTIFIER NULL,
    [BankID]              VARCHAR (250)    NULL,
    [RetailerName]        VARCHAR (250)    NULL,
    [Amount]              DECIMAL (8, 4)   NULL,
    [Currency]            VARCHAR (3)      NULL,
    [Expiry]              DATETIME2 (7)    NULL,
    [Redeemed]            BIT              NULL,
    [RedeemedDate]        DATETIME2 (7)    NULL,
    [CreatedAt]           DATETIME2 (7)    NULL,
    [UpdatedAt]           DATETIME2 (7)    NULL,
    [LoadDate]            DATETIME2 (7)    NULL,
    [FileName]            NVARCHAR (100)   NULL
);

