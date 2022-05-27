CREATE TABLE [InsightArchive].[UAE_ComboBrand_Original] (
    [ConsumerCombinationID] INT           NOT NULL,
    [BrandID]               SMALLINT      NOT NULL,
    [MID]                   VARCHAR (50)  NOT NULL,
    [Narrative]             VARCHAR (50)  NOT NULL,
    [MCC]                   VARCHAR (4)   NOT NULL,
    [MCCDesc]               VARCHAR (200) NOT NULL,
    [Brand]                 VARCHAR (50)  NOT NULL,
    [Sector]                VARCHAR (50)  NOT NULL,
    [CountryCode]           VARCHAR (2)   DEFAULT ('AE') NOT NULL,
    [Region]                VARCHAR (50)  DEFAULT ('') NOT NULL,
    [RegionRaw]             VARCHAR (50)  DEFAULT ('') NOT NULL,
    [LocationCategory]      VARCHAR (50)  DEFAULT ('NOTHING') NOT NULL,
    PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

