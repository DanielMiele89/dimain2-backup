CREATE TABLE [APW].[SpendPurchaseCount_CINSpend_Test] (
    [CINID]     INT   NOT NULL,
    [TranCount] INT   NOT NULL,
    [Spend]     MONEY NOT NULL,
    CONSTRAINT [PK_APW_SpendPurchaseCount_CINSpend_Test] PRIMARY KEY CLUSTERED ([CINID] ASC)
);

