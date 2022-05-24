CREATE TABLE [Staging].[Inbound_CharityOffers_20211124] (
    [ID]                    INT              IDENTITY (1, 1) NOT NULL,
    [CharityItemID]         BIGINT           NOT NULL,
    [CharityOfferGUID]      UNIQUEIDENTIFIER NOT NULL,
    [RedemptionPartnerGUID] UNIQUEIDENTIFIER NOT NULL,
    [BankID]                INT              NOT NULL,
    [CharityName]           VARCHAR (250)    NULL,
    [MinimumAmount]         MONEY            NOT NULL,
    [Currency]              VARCHAR (3)      NOT NULL,
    [Status]                VARCHAR (50)     NOT NULL,
    [Priority]              INT              NOT NULL,
    [CreatedAt]             DATETIME2 (7)    NOT NULL,
    [UpdatedAt]             DATETIME2 (7)    NOT NULL,
    [LoadDate]              DATETIME2 (7)    NOT NULL,
    [FileName]              NVARCHAR (320)   NOT NULL
);

