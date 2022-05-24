CREATE TABLE [Prototype].[AMEX_Seasonality_v2] (
    [MonthNum]      INT          NULL,
    [Year]          INT          NULL,
    [YYYYMM]        NUMERIC (18) NULL,
    [BrandName]     VARCHAR (50) NOT NULL,
    [All_sales]     MONEY        NULL,
    [All_trans]     INT          NULL,
    [All_Shoppers]  INT          NULL,
    [Year_Shoppers] INT          NULL,
    [Online_sales]  MONEY        NULL,
    [Online_trans]  INT          NULL,
    [Store_Sales]   MONEY        NULL,
    [Store_trans]   INT          NULL
);

