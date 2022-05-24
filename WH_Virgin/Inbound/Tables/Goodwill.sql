CREATE TABLE [Inbound].[Goodwill] (
    [CustomerID]       INT            NULL,
    [GoodwillAmount]   MONEY          NULL,
    [GoodwillDateTime] DATETIME2 (7)  NULL,
    [GoodwillType]     VARCHAR (100)  NULL,
    [VirginCustomerID] INT            NULL,
    [LoadDate]         DATETIME2 (7)  NULL,
    [FileName]         NVARCHAR (100) NULL
);

