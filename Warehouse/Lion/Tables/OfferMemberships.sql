CREATE TABLE [Lion].[OfferMemberships] (
    [PartnerID]    INT          NULL,
    [IronOfferID]  INT          NULL,
    [CompositeID]  BIGINT       NULL,
    [StartDate]    DATETIME     NULL,
    [EndDate]      DATETIME     NULL,
    [OfferRank]    INT          NULL,
    [OfferSegment] VARCHAR (20) NULL
);


GO
CREATE NONCLUSTERED INDEX [CSI_OfferDetails]
    ON [Lion].[OfferMemberships]([PartnerID] ASC, [IronOfferID] ASC, [CompositeID] ASC, [OfferRank] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Partner_IncOfferComp]
    ON [Lion].[OfferMemberships]([PartnerID] ASC)
    INCLUDE([IronOfferID], [CompositeID]) WITH (FILLFACTOR = 90);


GO
CREATE CLUSTERED INDEX [CIX_CompOffer]
    ON [Lion].[OfferMemberships]([CompositeID] ASC, [IronOfferID] ASC) WITH (FILLFACTOR = 90);

