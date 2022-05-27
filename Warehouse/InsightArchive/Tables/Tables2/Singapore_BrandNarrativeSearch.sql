CREATE TABLE [InsightArchive].[Singapore_BrandNarrativeSearch] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [SiloBrandID]      INT          NOT NULL,
    [NarrativePattern] VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    UNIQUE NONCLUSTERED ([NarrativePattern] ASC)
);

