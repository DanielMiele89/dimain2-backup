CREATE TABLE [InsightArchive].[NEW_DAILY_TRANSACTIONS] (
    [TranDate]     DATE         NULL,
    [BrandID]      SMALLINT     NOT NULL,
    [BrandName]    VARCHAR (50) NOT NULL,
    [SectorName]   VARCHAR (50) NULL,
    [GroupName]    VARCHAR (50) NULL,
    [IsOnline]     BIT          NOT NULL,
    [Sales]        MONEY        NULL,
    [Transactions] INT          NULL
);

