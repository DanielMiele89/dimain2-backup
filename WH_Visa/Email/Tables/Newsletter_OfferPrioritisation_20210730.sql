CREATE TABLE [Email].[Newsletter_OfferPrioritisation_20210730] (
    [PartnerID]   INT  NOT NULL,
    [IronOfferID] INT  NOT NULL,
    [Weighting]   INT  NOT NULL,
    [Base]        INT  NOT NULL,
    [NewOffer]    BIT  NULL,
    [EmailDate]   DATE NULL
);

