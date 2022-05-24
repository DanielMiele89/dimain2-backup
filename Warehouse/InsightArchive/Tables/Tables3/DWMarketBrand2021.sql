CREATE TABLE [InsightArchive].[DWMarketBrand2021] (
    [CINID]      INT          NOT NULL,
    [GroupName]  VARCHAR (50) NULL,
    [SectorName] VARCHAR (50) NULL,
    [BrandName]  VARCHAR (50) NOT NULL,
    [TranYear]   INT          NULL,
    [NumTrx]     INT          NULL,
    [Spend]      MONEY        NULL
);

