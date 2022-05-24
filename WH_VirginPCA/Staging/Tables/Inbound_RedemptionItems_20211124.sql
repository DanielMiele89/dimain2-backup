﻿CREATE TABLE [Staging].[Inbound_RedemptionItems_20211124] (
    [ID]                  INT              IDENTITY (1, 1) NOT NULL,
    [RedemptionItemID]    BIGINT           NOT NULL,
    [RedemptionOfferGUID] UNIQUEIDENTIFIER NOT NULL,
    [BankID]              INT              NULL,
    [RetailerName]        VARCHAR (250)    NULL,
    [Amount]              MONEY            NULL,
    [Currency]            VARCHAR (3)      NULL,
    [Expiry]              DATETIME2 (7)    NULL,
    [Redeemed]            BIT              NULL,
    [RedeemedDate]        DATETIME2 (7)    NULL,
    [CreatedAt]           DATETIME2 (7)    NULL,
    [UpdatedAt]           DATETIME2 (7)    NULL,
    [LoadDate]            DATETIME2 (7)    NOT NULL,
    [FileName]            NVARCHAR (320)   NOT NULL
);

