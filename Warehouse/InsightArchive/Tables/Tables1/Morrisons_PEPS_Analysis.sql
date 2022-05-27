CREATE TABLE [InsightArchive].[Morrisons_PEPS_Analysis] (
    [FanID]           INT              NOT NULL,
    [CINID]           INT              NOT NULL,
    [EngagementScore] VARCHAR (15)     NOT NULL,
    [RankingFeature]  REAL             NULL,
    [Segment]         VARCHAR (7)      NULL,
    [ShopperSub]      VARCHAR (15)     NULL,
    [PropensityScore] BIGINT           NULL,
    [BrandSoW]        NUMERIC (38, 17) NULL,
    [OnlineSales]     MONEY            NULL
);


GO
CREATE CLUSTERED INDEX [cix_CINID]
    ON [InsightArchive].[Morrisons_PEPS_Analysis]([CINID] ASC);

