CREATE TABLE [APW].[SpendPurchaseCount_CINSpend] (
    [CINID]     INT   NOT NULL,
    [TranCount] INT   NOT NULL,
    [Spend]     MONEY NOT NULL,
    CONSTRAINT [PK_APW_SpendPurchaseCount_CINSpend] PRIMARY KEY CLUSTERED ([CINID] ASC)
);

