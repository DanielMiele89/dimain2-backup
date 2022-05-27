CREATE TABLE [Relational].[PartnerOffers_Base_ProductType] (
    [ID]            INT IDENTITY (1, 1) NOT NULL,
    [IronOfferID]   INT NOT NULL,
    [ProductTypeID] INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);

