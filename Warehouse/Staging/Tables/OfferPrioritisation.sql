CREATE TABLE [Staging].[OfferPrioritisation] (
    [PartnerID]   INT  NOT NULL,
    [IronOfferID] INT  NOT NULL,
    [Weighting]   INT  NOT NULL,
    [Base]        INT  NOT NULL,
    [NewOffer]    BIT  NULL,
    [EmailDate]   DATE NULL
);


GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
    ON [Staging].[OfferPrioritisation]([Base] ASC, [NewOffer] ASC, [EmailDate] ASC)
    INCLUDE([PartnerID]);

