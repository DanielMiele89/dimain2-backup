CREATE TABLE [InsightArchive].[Online_YoY_Daily_level] (
    [TranDate]     DATE         NOT NULL,
    [BrandID]      SMALLINT     NOT NULL,
    [BrandName]    VARCHAR (50) NOT NULL,
    [SectorName]   VARCHAR (50) NULL,
    [GroupName]    VARCHAR (50) NULL,
    [ONLINE_SALES] MONEY        NULL
);

