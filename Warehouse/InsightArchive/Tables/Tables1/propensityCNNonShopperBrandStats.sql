CREATE TABLE [InsightArchive].[propensityCNNonShopperBrandStats] (
    [BrandID]      SMALLINT NOT NULL,
    [Spend]        MONEY    NOT NULL,
    [TranCount]    MONEY    NOT NULL,
    [SpenderCount] INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([BrandID] ASC)
);

