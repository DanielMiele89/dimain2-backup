CREATE TABLE [Inbound].[Goodwill] (
    [ID]               BIGINT           IDENTITY (1, 1) NOT NULL,
    [CustomerGUID]     UNIQUEIDENTIFIER NOT NULL,
    [GoodwillDateTime] DATETIME2 (7)    NOT NULL,
    [GoodwillAmount]   MONEY            NOT NULL,
    [LoadDate]         DATETIME2 (7)    NOT NULL,
    [FileName]         NVARCHAR (320)   NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

