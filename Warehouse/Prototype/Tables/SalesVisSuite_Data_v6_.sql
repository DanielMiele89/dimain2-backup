CREATE TABLE [Prototype].[SalesVisSuite_Data_v6_] (
    [MonthNum]        INT          NULL,
    [Year]            INT          NULL,
    [YYYYMM]          NUMERIC (18) NULL,
    [BrandName]       VARCHAR (50) NOT NULL,
    [All_Sales]       MONEY        NULL,
    [All_Trans]       INT          NULL,
    [All_Shoppers]    INT          NULL,
    [Online_Sales]    MONEY        NULL,
    [Online_Trans]    INT          NULL,
    [Online_Shoppers] INT          NULL,
    [Store_Sales]     MONEY        NULL,
    [Store_Trans]     INT          NULL,
    [Store_Shoppers]  INT          NULL
);

