CREATE TABLE [ExcelQuery].[SalesVisSuite_Data_v7] (
    [MonthNum]     INT          NULL,
    [Year]         INT          NULL,
    [YYYYMM]       NUMERIC (18) NULL,
    [BrandName]    VARCHAR (50) NOT NULL,
    [Channel]      VARCHAR (50) NOT NULL,
    [Sales]        MONEY        NULL,
    [Transactions] INT          NULL,
    [Spenders]     INT          NULL
);

