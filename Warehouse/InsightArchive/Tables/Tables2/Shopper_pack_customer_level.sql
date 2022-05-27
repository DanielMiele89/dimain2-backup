CREATE TABLE [InsightArchive].[Shopper_pack_customer_level] (
    [cinid]            INT          NOT NULL,
    [main_brand]       VARCHAR (50) NOT NULL,
    [main_brand_spend] MONEY        NULL,
    [competitor_spend] MONEY        NULL,
    [sales]            MONEY        NULL,
    [transactions]     INT          NULL,
    [ntile]            BIGINT       NULL
);

