CREATE TABLE [Inbound].[__Offer_Archived] (
    [OfferGUID]           UNIQUEIDENTIFIER NOT NULL,
    [OfferName]           VARCHAR (255)    NULL,
    [StartDate]           DATETIME2 (7)    NULL,
    [EndDate]             DATETIME2 (7)    NULL,
    [RetailerGUID]        UNIQUEIDENTIFIER NULL,
    [PublisherGUID]       UNIQUEIDENTIFIER NULL,
    [OfferChannelID]      INT              NULL,
    [CurrencyID]          INT              NULL,
    [OfferDetailGUID]     UNIQUEIDENTIFIER NULL,
    [PrioritisationScore] INT              NULL,
    [OfferStatusID]       INT              NULL,
    [CreatedDate]         DATETIME2 (7)    NULL,
    [UpdatedDate]         DATETIME2 (7)    NULL,
    [PublishedDate]       DATETIME2 (7)    NULL,
    [LoadDate]            DATETIME2 (7)    NULL,
    [FileName]            NVARCHAR (100)   NULL,
    [ArchiveDate]         DATETIME2 (7)    NULL
);

