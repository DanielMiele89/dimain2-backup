CREATE TABLE [Staging].[R_0102_DD_DataTable_CBP] (
    [StartOfMonth]     DATETIME      NULL,
    [InternalCategory] VARCHAR (30)  NULL,
    [SupplierID]       INT           NOT NULL,
    [SupplierName]     VARCHAR (250) NOT NULL,
    [TotalAmountSpent] MONEY         NULL,
    [Transactions]     INT           NULL,
    [Customers]        INT           NULL
);

