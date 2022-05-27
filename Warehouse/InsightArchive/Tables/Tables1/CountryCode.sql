CREATE TABLE [InsightArchive].[CountryCode] (
    [ID]            TINYINT       IDENTITY (1, 1) NOT NULL,
    [CountryName]   VARCHAR (100) NOT NULL,
    [CodeTwoChar]   VARCHAR (2)   NOT NULL,
    [CodeThreeChar] VARCHAR (3)   NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

