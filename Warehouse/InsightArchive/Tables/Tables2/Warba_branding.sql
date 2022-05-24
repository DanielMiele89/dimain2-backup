CREATE TABLE [InsightArchive].[Warba_branding] (
    [ID]         INT           IDENTITY (1, 1) NOT NULL,
    [Narrative]  VARCHAR (50)  NOT NULL,
    [MID]        VARCHAR (50)  NOT NULL,
    [MCC]        VARCHAR (50)  NOT NULL,
    [MCCDesc]    VARCHAR (100) NOT NULL,
    [SectorName] VARCHAR (50)  NOT NULL,
    [BrandName]  VARCHAR (50)  NOT NULL,
    [GroupName]  VARCHAR (50)  NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

