CREATE TABLE [Vernon].[Brand_daily_household] (
    [BrandName]          VARCHAR (50) NOT NULL,
    [SectorName]         VARCHAR (50) NULL,
    [GroupName]          VARCHAR (50) NULL,
    [TranDate]           DATE         NOT NULL,
    [sales]              MONEY        NULL,
    [total_transactions] INT          NULL,
    [daily_customers]    INT          NULL,
    [IsOnline]           BIT          NOT NULL,
    [YYYY-MM]            VARCHAR (7)  NULL
);

