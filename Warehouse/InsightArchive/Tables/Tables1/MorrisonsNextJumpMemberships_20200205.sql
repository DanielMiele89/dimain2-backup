CREATE TABLE [InsightArchive].[MorrisonsNextJumpMemberships_20200205] (
    [IronOfferID] INT    NOT NULL,
    [CompositeID] BIGINT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_IronOfferIDCompositeID]
    ON [InsightArchive].[MorrisonsNextJumpMemberships_20200205]([IronOfferID] ASC, [CompositeID] ASC);

