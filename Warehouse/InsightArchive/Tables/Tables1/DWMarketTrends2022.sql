CREATE TABLE [InsightArchive].[DWMarketTrends2022] (
    [CINID]              INT          NOT NULL,
    [GroupName]          VARCHAR (50) NULL,
    [IsOnline]           BIT          NOT NULL,
    [TranYear]           INT          NULL,
    [TranMonth]          VARCHAR (2)  NULL,
    [NumTrx]             INT          NULL,
    [NumBrandsPurchased] INT          NULL,
    [Spend]              MONEY        NULL
);

