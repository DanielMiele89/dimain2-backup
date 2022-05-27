CREATE TABLE [Report].[OfferLinks] (
    [ID]               INT IDENTITY (1, 1) NOT NULL,
    [OfferAttributeID] INT NOT NULL,
    [OfferID]          INT NOT NULL,
    [IronOfferID]      INT NOT NULL,
    CONSTRAINT [PK__OfferLin__3214EC27D82B4CE6] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX_OfferLinks]
    ON [Report].[OfferLinks]([IronOfferID] ASC)
    INCLUDE([OfferAttributeID]);

