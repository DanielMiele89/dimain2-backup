CREATE TABLE [InsightArchive].[MFDD_Sky_20190606] (
    [SourceUID] VARCHAR (20) NULL,
    [Segment]   VARCHAR (9)  NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_SourceUID]
    ON [InsightArchive].[MFDD_Sky_20190606]([SourceUID] ASC);

