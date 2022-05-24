CREATE TABLE [InsightArchive].[NEW_DAILY_TRANSACTIONS_CUSTOM_SECTORS] (
    [GroupName]     VARCHAR (50) NULL,
    [SectorName]    VARCHAR (50) NULL,
    [Custom Sector] VARCHAR (23) NOT NULL,
    [BrandName]     VARCHAR (50) NOT NULL,
    [TranDate]      DATE         NULL,
    [IsOnline]      BIT          NOT NULL,
    [TOTAL_SALES]   MONEY        NULL,
    [TOTAL_RETURNS] MONEY        NULL
);

