CREATE TABLE [InsightArchive].[NewsletterSend_20171124_ImpactedOffers] (
    [IronOfferID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_NewsletterSend_20171124_ImpactedOffers_IronOfferID]
    ON [InsightArchive].[NewsletterSend_20171124_ImpactedOffers]([IronOfferID] ASC);

