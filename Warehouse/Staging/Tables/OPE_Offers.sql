CREATE TABLE [Staging].[OPE_Offers] (
    [IronOfferID] INT  NULL,
    [PartnerID]   INT  NULL,
    [StartDate]   DATE NULL,
    [EndDate]     DATE NULL,
    [HTMID]       INT  NULL,
    [BaseOffer]   INT  NULL
);


GO
CREATE NONCLUSTERED INDEX [idx_OPE_Offers_PartnerID]
    ON [Staging].[OPE_Offers]([PartnerID] ASC);


GO
CREATE CLUSTERED INDEX [idx_OPE_Offers_OfferAndHTM]
    ON [Staging].[OPE_Offers]([IronOfferID] ASC, [HTMID] ASC);

