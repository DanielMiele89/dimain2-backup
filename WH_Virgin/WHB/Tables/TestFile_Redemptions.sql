CREATE TABLE [WHB].[TestFile_Redemptions] (
    [CustomerID]     INT            NULL,
    [RedemptionDate] DATETIME2 (7)  NULL,
    [RedemptionType] VARCHAR (8)    NULL,
    [Amount]         SMALLMONEY     NULL,
    [LoadDate]       DATETIME2 (7)  NULL,
    [FileName]       NVARCHAR (100) NULL
);

