CREATE TABLE [InsightArchive].[fr_postal_codes] (
    [Postal Code] VARCHAR (50) NULL,
    [Place Name]  VARCHAR (50) NULL,
    [State]       VARCHAR (50) NULL,
    [County]      VARCHAR (50) NULL,
    [City]        VARCHAR (50) NULL,
    [Latitude]    VARCHAR (50) NULL,
    [Longitude]   VARCHAR (50) NULL,
    [PostCode]    VARCHAR (5)  DEFAULT ('') NOT NULL
);

