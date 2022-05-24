CREATE TABLE [InsightArchive].[Ukraine_BrandSearch] (
    [SiloBrandid]      INT          IDENTITY (1, 1) NOT NULL,
    [BrandID_Existing] INT          NULL,
    [BrandName]        VARCHAR (50) NOT NULL,
    [SectorID]         TINYINT      NOT NULL,
    [IsComplete]       BIT          DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([SiloBrandid] ASC)
);

