CREATE TABLE [Inbound].[__RedemptionItem_Archived] (
    [RedemptionItemGUID]    UNIQUEIDENTIFIER NULL,
    [RedemptionType]        VARCHAR (8)      NULL,
    [RedemptionDescription] VARCHAR (255)    NULL,
    [RetailerGUID]          UNIQUEIDENTIFIER NULL,
    [RedemptionValue]       MONEY            NULL,
    [TradeUpValue]          MONEY            NULL,
    [LoadDate]              DATETIME2 (7)    NULL,
    [FileName]              NVARCHAR (100)   NULL
);

