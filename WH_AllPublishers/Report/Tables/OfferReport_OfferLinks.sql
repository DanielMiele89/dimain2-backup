CREATE TABLE [Report].[OfferReport_OfferLinks] (
    [ID]               INT IDENTITY (1, 1) NOT NULL,
    [OfferAttributeID] INT NOT NULL,
    [OfferID]          INT NOT NULL,
    [IronOfferID]      INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX_OfferLinks]
    ON [Report].[OfferReport_OfferLinks]([OfferID] ASC)
    INCLUDE([OfferAttributeID]);

