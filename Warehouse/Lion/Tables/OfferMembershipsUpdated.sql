CREATE TABLE [Lion].[OfferMembershipsUpdated] (
    [PartnerID]    INT      NULL,
    [IronOfferID]  INT      NULL,
    [CompositeID]  BIGINT   NULL,
    [StartDate]    DATETIME NULL,
    [EndDate]      DATETIME NULL,
    [OfferRank]    INT      NULL,
    [OfferSegment] INT      NULL
);


GO
CREATE CLUSTERED INDEX [CSI_All]
    ON [Lion].[OfferMembershipsUpdated]([CompositeID] ASC, [OfferSegment] ASC, [OfferRank] ASC) WITH (FILLFACTOR = 90);

