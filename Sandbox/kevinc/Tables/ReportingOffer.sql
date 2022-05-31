CREATE TABLE [kevinc].[ReportingOffer] (
    [ReportingOfferID] INT           IDENTITY (1, 1) NOT NULL,
    [IronOfferID]      INT           NOT NULL,
    [OfferTypeID]      INT           NOT NULL,
    [PublisherID]      INT           NOT NULL,
    [StartDate]        DATETIME2 (7) NULL,
    [EndDate]          DATETIME2 (7) NULL,
    [PartnerID]        INT           NULL
);

