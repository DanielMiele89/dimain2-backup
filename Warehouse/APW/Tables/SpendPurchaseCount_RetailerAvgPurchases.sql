CREATE TABLE [APW].[SpendPurchaseCount_RetailerAvgPurchases] (
    [ID]            INT        IDENTITY (1, 1) NOT NULL,
    [RetailerID]    INT        NOT NULL,
    [IsControl]     BIT        NOT NULL,
    [TranCount]     INT        NOT NULL,
    [CustomerCount] INT        NOT NULL,
    [AvgPurchases]  FLOAT (53) NOT NULL,
    CONSTRAINT [PK_APW_SpendPurchaseCount_RetailerAvgPurchases] PRIMARY KEY CLUSTERED ([ID] ASC)
);

