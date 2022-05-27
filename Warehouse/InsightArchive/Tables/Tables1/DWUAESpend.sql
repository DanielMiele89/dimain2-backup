CREATE TABLE [InsightArchive].[DWUAESpend] (
    [CINID]      INT          NOT NULL,
    [BrandName2] VARCHAR (50) NULL,
    [SectorName] VARCHAR (50) NULL,
    [GroupName]  VARCHAR (50) NULL,
    [TranYear]   INT          NULL,
    [TranMonth]  INT          NULL,
    [NumTrx]     INT          NULL,
    [Spend]      MONEY        NULL
);

