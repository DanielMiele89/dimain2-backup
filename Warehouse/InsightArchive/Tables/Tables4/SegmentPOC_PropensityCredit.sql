CREATE TABLE [InsightArchive].[SegmentPOC_PropensityCredit] (
    [BrandID]      INT          NULL,
    [CycleStart]   DATE         NULL,
    [CINID]        INT          NULL,
    [Sales]        MONEY        NULL,
    [Trans]        INT          NULL,
    [LatestTran]   DATE         NULL,
    [HeatmapIndex] REAL         NULL,
    [Segment]      VARCHAR (20) NULL
);


GO
CREATE NONCLUSTERED INDEX [nix_CINID]
    ON [InsightArchive].[SegmentPOC_PropensityCredit]([CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [nix_CycleStartCINID]
    ON [InsightArchive].[SegmentPOC_PropensityCredit]([CycleStart] ASC)
    INCLUDE([CINID]);


GO
CREATE CLUSTERED INDEX [cix_CycleStart]
    ON [InsightArchive].[SegmentPOC_PropensityCredit]([CycleStart] ASC);

