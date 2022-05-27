CREATE TABLE [InsightArchive].[UAE_MIDLocData] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]          SMALLINT     NOT NULL,
    [MID]              VARCHAR (50) NOT NULL,
    [CountryCode]      VARCHAR (2)  NOT NULL,
    [LocationCategory] VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

