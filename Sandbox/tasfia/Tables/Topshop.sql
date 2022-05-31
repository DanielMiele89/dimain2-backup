CREATE TABLE [tasfia].[Topshop] (
    [BrandName]    VARCHAR (50) NOT NULL,
    [TranDate]     DATE         NOT NULL,
    [PrePost]      VARCHAR (4)  NOT NULL,
    [CreditDebit]  TINYINT      NOT NULL,
    [IsOnline]     BIT          NOT NULL,
    [Spend]        MONEY        NULL,
    [Customers]    INT          NULL,
    [Transactions] INT          NULL
);


GO
CREATE CLUSTERED INDEX [ix_BrandName]
    ON [tasfia].[Topshop]([BrandName] ASC);

