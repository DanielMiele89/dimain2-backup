CREATE TABLE [Inbound].[Offer] (
    [ID]                  BIGINT           IDENTITY (1, 1) NOT NULL,
    [OfferGUID]           UNIQUEIDENTIFIER NULL,
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
    [LoadDate]            DATETIME2 (7)    NOT NULL,
    [FileName]            NVARCHAR (320)   NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

