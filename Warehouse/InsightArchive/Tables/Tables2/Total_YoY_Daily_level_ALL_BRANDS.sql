﻿CREATE TABLE [InsightArchive].[Total_YoY_Daily_level_ALL_BRANDS] (
    [TranDate]    DATE         NOT NULL,
    [BrandID]     SMALLINT     NOT NULL,
    [BrandName]   VARCHAR (50) NOT NULL,
    [SectorName]  VARCHAR (50) NULL,
    [GroupName]   VARCHAR (50) NULL,
    [TOTAL_SALES] MONEY        NULL
);

