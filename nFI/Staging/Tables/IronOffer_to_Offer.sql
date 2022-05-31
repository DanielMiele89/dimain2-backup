CREATE TABLE [Staging].[IronOffer_to_Offer] (
    [ID]          INT IDENTITY (1, 1) NOT NULL,
    [IronOfferID] INT NULL,
    [OfferID]     INT NULL,
    [IsRoc]       BIT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

