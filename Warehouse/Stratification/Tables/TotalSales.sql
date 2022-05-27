CREATE TABLE [Stratification].[TotalSales] (
    [MonthID]           INT   NOT NULL,
    [CINID]             INT   NULL,
    [TotalSales]        MONEY NULL,
    [TotalTransactions] INT   NULL
);


GO
CREATE CLUSTERED INDEX [IND_CARD]
    ON [Stratification].[TotalSales]([CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_M]
    ON [Stratification].[TotalSales]([MonthID] ASC);

