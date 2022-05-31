CREATE TABLE [tasfia].[MatalanMarketShift] (
    [MatalanGroup] VARCHAR (20)  NULL,
    [BrandName]    VARCHAR (50)  NOT NULL,
    [TranDate]     DATE          NOT NULL,
    [PrePost]      VARCHAR (4)   NOT NULL,
    [CreditDebit]  TINYINT       NOT NULL,
    [IsOnline]     BIT           NOT NULL,
    [Spend]        MONEY         NULL,
    [Customers]    INT           NULL,
    [Transactions] INT           NULL,
    [MainBrand]    VARCHAR (500) NULL,
    [ReportName]   VARCHAR (500) NULL,
    [Version]      INT           NULL
);

