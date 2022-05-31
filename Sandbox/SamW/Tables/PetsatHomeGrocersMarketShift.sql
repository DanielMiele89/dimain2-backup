CREATE TABLE [SamW].[PetsatHomeGrocersMarketShift] (
    [Group]        VARCHAR (12)  NOT NULL,
    [BrandName]    VARCHAR (50)  NOT NULL,
    [TranDate]     DATE          NOT NULL,
    [Period]       VARCHAR (8)   NULL,
    [CreditDebit]  TINYINT       NOT NULL,
    [IsOnline]     BIT           NOT NULL,
    [Spend]        MONEY         NULL,
    [Customers]    INT           NULL,
    [Transactions] INT           NULL,
    [MainBrand]    VARCHAR (500) NULL,
    [ReportName]   VARCHAR (500) NULL,
    [Version]      INT           NULL
);

