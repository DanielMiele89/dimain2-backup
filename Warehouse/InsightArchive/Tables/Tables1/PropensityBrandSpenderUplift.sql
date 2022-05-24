CREATE TABLE [InsightArchive].[PropensityBrandSpenderUplift] (
    [ID]                      INT        IDENTITY (1, 1) NOT NULL,
    [TargetBrandID]           SMALLINT   NOT NULL,
    [BrandID]                 SMALLINT   NOT NULL,
    [ShopperSpenderCount]     FLOAT (53) NOT NULL,
    [ShopperCustomerCount]    FLOAT (53) NOT NULL,
    [NonShopperSpenderCount]  FLOAT (53) NOT NULL,
    [NonShopperCustomerCount] FLOAT (53) NOT NULL,
    [PercentShopperUplift]    FLOAT (53) DEFAULT ((0)) NOT NULL,
    [AbsPercentShopperUplift] FLOAT (53) DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

