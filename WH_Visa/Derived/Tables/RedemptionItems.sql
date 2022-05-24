CREATE TABLE [Derived].[RedemptionItems] (
    [ID]                    INT              IDENTITY (1, 1) NOT NULL,
    [BankID]                VARCHAR (250)    NULL,
    [RedemptionPartnerGUID] UNIQUEIDENTIFIER NULL,
    [RedemptionOfferGUID]   UNIQUEIDENTIFIER NULL,
    [RedemptionItemID]      INT              NOT NULL,
    [Amount]                DECIMAL (8, 4)   NULL,
    [Currency]              VARCHAR (3)      NULL,
    [Expiry]                DATETIME2 (7)    NULL,
    [Redeemed]              BIT              NULL,
    [RedeemedDate]          DATETIME2 (7)    NULL
);

