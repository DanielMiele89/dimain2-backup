CREATE TABLE [InsightArchive].[GreenekingMS] (
    [main_brand]       VARCHAR (50)  NULL,
    [BrandName]        VARCHAR (50)  NOT NULL,
    [week_commencing]  DATE          NULL,
    [month_commencing] DATE          NULL,
    [Store_Location]   VARCHAR (200) NULL,
    [Store_County]     VARCHAR (200) NULL,
    [PostCode]         VARCHAR (50)  NOT NULL,
    [amount]           MONEY         NULL,
    [transactions]     INT           NULL
);

