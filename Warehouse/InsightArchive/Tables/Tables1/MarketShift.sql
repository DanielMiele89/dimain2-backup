CREATE TABLE [InsightArchive].[MarketShift] (
    [Group]        VARCHAR (10)  NULL,
    [BrandName]    VARCHAR (50)  NOT NULL,
    [TranDate]     DATE          NOT NULL,
    [Period]       VARCHAR (5)   NULL,
    [CreditDebit]  TINYINT       NOT NULL,
    [IsOnline]     BIT           NOT NULL,
    [Spend]        MONEY         NULL,
    [Customers]    INT           NULL,
    [Transactions] INT           NULL,
    [MainBrand]    VARCHAR (500) NULL,
    [ReportName]   VARCHAR (500) NULL,
    [Version]      INT           NULL
);

