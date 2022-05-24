CREATE TABLE [InsightArchive].[GROCERY_TOP_10_BY_DAY] (
    [TranDate]          DATE         NULL,
    [BrandID]           SMALLINT     NOT NULL,
    [BrandName]         VARCHAR (50) NOT NULL,
    [IsOnline]          BIT          NOT NULL,
    [Sales_2022]        MONEY        NULL,
    [Transactions_2022] INT          NULL,
    [Customers_2022]    INT          NULL,
    [Sales_2021]        MONEY        NULL,
    [Transactions_2021] INT          NULL,
    [Customers_2021]    INT          NULL
);

