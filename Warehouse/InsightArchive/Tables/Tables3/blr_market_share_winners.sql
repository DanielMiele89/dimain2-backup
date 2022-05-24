CREATE TABLE [InsightArchive].[blr_market_share_winners] (
    [Main_brand]       VARCHAR (50) NULL,
    [region]           VARCHAR (30) NULL,
    [PostCodeDistrict] VARCHAR (4)  NULL,
    [BrandName]        VARCHAR (50) NOT NULL,
    [month_commencing] DATE         NULL,
    [amount]           MONEY        NULL,
    [market_share]     MONEY        NULL,
    [ranking]          BIGINT       NULL
);

