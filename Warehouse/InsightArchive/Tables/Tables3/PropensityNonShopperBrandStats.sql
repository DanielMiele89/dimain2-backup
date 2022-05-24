CREATE TABLE [InsightArchive].[PropensityNonShopperBrandStats] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [TargetBrandID] SMALLINT NOT NULL,
    [BrandID]       SMALLINT NOT NULL,
    [Spend]         MONEY    NOT NULL,
    [TranCount]     MONEY    NOT NULL,
    [SpenderCount]  INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

