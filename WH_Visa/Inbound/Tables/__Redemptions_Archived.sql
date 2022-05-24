CREATE TABLE [Inbound].[__Redemptions_Archived] (
    [RedemptionGUID]     UNIQUEIDENTIFIER NULL,
    [CustomerGUID]       UNIQUEIDENTIFIER NULL,
    [RedemptionDate]     DATETIME2 (7)    NULL,
    [RedemptionItemGUID] UNIQUEIDENTIFIER NULL,
    [RedemptionType]     VARCHAR (8)      NULL,
    [Amount]             MONEY            NULL,
    [LoadDate]           DATETIME2 (7)    NULL,
    [FileName]           NVARCHAR (100)   NULL
);

