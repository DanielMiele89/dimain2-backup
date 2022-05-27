﻿CREATE TABLE [Lion].[OfferMemberships_2] (
    [PartnerID]    INT          NULL,
    [IronOfferID]  INT          NULL,
    [CompositeID]  BIGINT       NULL,
    [StartDate]    DATETIME     NULL,
    [EndDate]      DATETIME     NULL,
    [OfferRank]    INT          NULL,
    [OfferSegment] VARCHAR (20) NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CompOffer]
    ON [Lion].[OfferMemberships_2]([CompositeID] ASC, [IronOfferID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Partner_IncOfferComp]
    ON [Lion].[OfferMemberships_2]([PartnerID] ASC)
    INCLUDE([IronOfferID], [CompositeID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [CSI_OfferDetails]
    ON [Lion].[OfferMemberships_2]([PartnerID] ASC, [IronOfferID] ASC, [CompositeID] ASC, [OfferRank] ASC) WITH (FILLFACTOR = 90);

