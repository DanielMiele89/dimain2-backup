CREATE TABLE [Prototype].[Analysis_MarketShare] (
    [BrandID]            SMALLINT         NOT NULL,
    [BrandName]          VARCHAR (50)     NOT NULL,
    [Brand_Spend]        MONEY            NULL,
    [TotalSpend]         MONEY            NULL,
    [MarketShare_Spend]  MONEY            NULL,
    [Brand_Trans]        INT              NULL,
    [TotalTrans]         INT              NULL,
    [MarketShare_Trans]  NUMERIC (24, 12) NULL,
    [Brand_Customers]    INT              NULL,
    [TotalShoppers]      INT              NULL,
    [Market_Penetration] NUMERIC (24, 12) NULL
);

