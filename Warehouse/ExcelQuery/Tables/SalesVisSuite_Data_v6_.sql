CREATE TABLE [ExcelQuery].[SalesVisSuite_Data_v6_] (
    [MonthNum]     INT          NULL,
    [Year]         INT          NULL,
    [YYYYMM]       NUMERIC (18) NULL,
    [BrandName]    VARCHAR (50) NOT NULL,
    [All_sales]    MONEY        NULL,
    [All_trans]    INT          NULL,
    [Online_sales] MONEY        NULL,
    [Online_trans] INT          NULL,
    [Store_Sales]  MONEY        NULL,
    [Store_trans]  INT          NULL
);

