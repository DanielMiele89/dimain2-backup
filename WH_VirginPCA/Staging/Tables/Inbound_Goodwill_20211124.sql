CREATE TABLE [Staging].[Inbound_Goodwill_20211124] (
    [ID]               BIGINT           IDENTITY (1, 1) NOT NULL,
    [CustomerGUID]     UNIQUEIDENTIFIER NOT NULL,
    [GoodwillDateTime] DATETIME2 (7)    NOT NULL,
    [GoodwillAmount]   MONEY            NOT NULL,
    [GoodwillType]     INT              NULL,
    [LoadDate]         DATETIME2 (7)    NOT NULL,
    [FileName]         NVARCHAR (320)   NOT NULL
);

