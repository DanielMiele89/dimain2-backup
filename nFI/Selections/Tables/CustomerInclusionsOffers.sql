CREATE TABLE [Selections].[CustomerInclusionsOffers] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]     INT          NULL,
    [ClubID]        INT          NULL,
    [IronOfferID]   INT          NULL,
    [IronOfferName] VARCHAR (50) NULL,
    [StartDate]     DATE         NULL,
    [EndDate]       DATE         NULL
);

