CREATE TABLE [APW].[ControlRetailerSpendPurchaseCountRAW] (
    [CINID]     INT   IDENTITY (1, 1) NOT NULL,
    [Spend]     MONEY NOT NULL,
    [TranCount] INT   NOT NULL,
    CONSTRAINT [PK_APW_ControlRetailerSpendPurchaseCount] PRIMARY KEY CLUSTERED ([CINID] ASC)
);

