CREATE TABLE [Inbound].[CharityOffers] (
    [CharityItemID]         INT              NOT NULL,
    [CharityOfferGUID]      UNIQUEIDENTIFIER NULL,
    [RedemptionPartnerGUID] UNIQUEIDENTIFIER NULL,
    [BankID]                VARCHAR (250)    NULL,
    [CharityName]           VARCHAR (250)    NULL,
    [MinimumAmount]         DECIMAL (8, 4)   NULL,
    [Currency]              VARCHAR (3)      NULL,
    [Status]                VARCHAR (50)     NULL,
    [Priority]              INT              NOT NULL,
    [CreatedAt]             DATETIME2 (7)    NULL,
    [UpdatedAt]             DATETIME2 (7)    NULL,
    [LoadDate]              DATETIME2 (7)    NULL,
    [FileName]              NVARCHAR (100)   NULL
);

