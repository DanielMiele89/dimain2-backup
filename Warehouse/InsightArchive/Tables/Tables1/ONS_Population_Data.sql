CREATE TABLE [InsightArchive].[ONS_Population_Data] (
    [ID]         INT          IDENTITY (1, 1) NOT NULL,
    [Gender]     VARCHAR (50) NOT NULL,
    [Age]        VARCHAR (50) NOT NULL,
    [Region]     VARCHAR (50) NOT NULL,
    [Population] INT          NOT NULL,
    [InsertDate] DATE         NOT NULL,
    [EndDate]    DATE         NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

