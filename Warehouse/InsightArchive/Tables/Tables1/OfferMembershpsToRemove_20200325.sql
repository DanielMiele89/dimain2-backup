CREATE TABLE [InsightArchive].[OfferMembershpsToRemove_20200325] (
    [IronOfferID]           INT          IDENTITY (1, 1) NOT NULL,
    [StartDate]             VARCHAR (23) NOT NULL,
    [DeletedFromProduction] BIT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_StartDateIronOffer]
    ON [InsightArchive].[OfferMembershpsToRemove_20200325]([StartDate] ASC, [IronOfferID] ASC);

