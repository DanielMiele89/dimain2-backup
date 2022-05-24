CREATE TABLE [Staging].[Inbound_Goodwill_20210110] (
    [CustomerGUID]     UNIQUEIDENTIFIER NULL,
    [GoodwillAmount]   MONEY            NULL,
    [GoodwillDateTime] DATETIME2 (7)    NULL,
    [GoodwillType]     VARCHAR (100)    NULL,
    [LoadDate]         DATETIME2 (7)    NULL,
    [FileName]         NVARCHAR (100)   NULL
);

