CREATE TABLE [Rory].[Members] (
    [PublisherType] VARCHAR (25)  NULL,
    [PublisherID]   INT           NULL,
    [RetailerID]    INT           NULL,
    [PartnerID]     INT           NULL,
    [IronOfferID]   INT           NULL,
    [OfferID]       INT           NOT NULL,
    [StartDate]     DATETIME      NULL,
    [EndDate]       DATETIME      NULL,
    [Cardholders]   INT           NULL,
    [EntrySource]   VARCHAR (100) NULL
);

