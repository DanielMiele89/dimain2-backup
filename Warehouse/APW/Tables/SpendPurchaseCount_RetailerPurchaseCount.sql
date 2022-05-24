CREATE TABLE [APW].[SpendPurchaseCount_RetailerPurchaseCount] (
    [ID]            INT     IDENTITY (1, 1) NOT NULL,
    [RetailerID]    INT     NOT NULL,
    [IsControl]     BIT     NOT NULL,
    [PurchaseCount] TINYINT NOT NULL,
    [CustomerCount] INT     NOT NULL,
    CONSTRAINT [PK_APW_SpendPurchaseCount_RetailerPurchaseCount] PRIMARY KEY CLUSTERED ([ID] ASC)
);

