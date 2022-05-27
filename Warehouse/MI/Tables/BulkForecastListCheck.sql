CREATE TABLE [MI].[BulkForecastListCheck] (
    [BrandName]      NVARCHAR (100)  NULL,
    [Lapsed]         BIT             NULL,
    [SpendThreshold] MONEY           NULL,
    [Sector]         NVARCHAR (100)  NULL,
    [Split]          NVARCHAR (4000) NULL,
    [BrandCheck]     INT             NOT NULL
);

