CREATE TABLE [InsightArchive].[MFDD_SkyForecast_11042019to11032020_05092019] (
    [SourceUID] VARCHAR (20) NULL,
    [Segment]   VARCHAR (9)  NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_SourceUID]
    ON [InsightArchive].[MFDD_SkyForecast_11042019to11032020_05092019]([SourceUID] ASC);

