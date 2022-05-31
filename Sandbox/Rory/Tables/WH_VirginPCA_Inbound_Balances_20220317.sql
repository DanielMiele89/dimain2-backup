CREATE TABLE [Rory].[WH_VirginPCA_Inbound_Balances_20220317] (
    [ID]                    BIGINT           IDENTITY (1, 1) NOT NULL,
    [CustomerGUID]          UNIQUEIDENTIFIER NOT NULL,
    [CashbackAvailable]     MONEY            NOT NULL,
    [CashbackPending]       MONEY            NOT NULL,
    [CashbackLifeTimeValue] MONEY            NOT NULL,
    [CreatedAt]             DATETIME2 (7)    NOT NULL,
    [UpdatedAt]             DATETIME2 (7)    NOT NULL,
    [LastUpdated]           DATETIME2 (7)    NULL,
    [LoadDate]              DATETIME2 (7)    NOT NULL,
    [FileName]              NVARCHAR (320)   NOT NULL
);

