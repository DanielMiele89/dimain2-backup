CREATE TABLE [Inbound].[ReprocessingCards] (
    [HashKey]          UNIQUEIDENTIFIER NULL,
    [SortKey]          VARCHAR (100)    NULL,
    [RewardAccountId]  UNIQUEIDENTIFIER NULL,
    [RewardCardId]     UNIQUEIDENTIFIER NULL,
    [RewardCustomerId] UNIQUEIDENTIFIER NULL,
    [VirginCardId]     VARCHAR (100)    NULL,
    [LoadDate]         DATETIME2 (7)    NULL,
    [FileName]         VARCHAR (100)    NULL
);

