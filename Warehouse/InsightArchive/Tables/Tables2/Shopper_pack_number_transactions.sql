CREATE TABLE [InsightArchive].[Shopper_pack_number_transactions] (
    [main_brand]           VARCHAR (50)     NULL,
    [BrandName]            VARCHAR (50)     NOT NULL,
    [Transactions]         INT              NULL,
    [Sales]                MONEY            NULL,
    [customers]            INT              NULL,
    [% of Brand Customers] NUMERIC (26, 14) NULL
);

