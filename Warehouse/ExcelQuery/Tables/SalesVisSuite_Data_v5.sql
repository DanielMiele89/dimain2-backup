CREATE TABLE [ExcelQuery].[SalesVisSuite_Data_v5] (
    [TranDate]     DATE         NOT NULL,
    [TranDate_2]   DATE         NOT NULL,
    [WeekNum]      INT          NULL,
    [MonthNum]     INT          NULL,
    [Year]         INT          NULL,
    [BrandName]    VARCHAR (50) NOT NULL,
    [All_sales]    MONEY        NULL,
    [All_trans]    INT          NULL,
    [Online_sales] MONEY        NULL,
    [Online_trans] INT          NULL,
    [Store_Sales]  MONEY        NULL,
    [Store_trans]  INT          NULL
);

