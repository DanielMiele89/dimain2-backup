CREATE TABLE [Selections].[OfferPrioritisation] (
    [PartnerID]   INT  NOT NULL,
    [IronOfferID] INT  NOT NULL,
    [Weighting]   INT  NOT NULL,
    [Base]        INT  NOT NULL,
    [NewOffer]    BIT  NULL,
    [EmailDate]   DATE NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_OfferPrioritisation_DateOffer]
    ON [Selections].[OfferPrioritisation]([EmailDate] ASC, [IronOfferID] ASC, [Weighting] ASC);


GO
CREATE CLUSTERED INDEX [CIX_OfferPrioritisation_EmailDateWeighting]
    ON [Selections].[OfferPrioritisation]([EmailDate] ASC, [Weighting] DESC);

