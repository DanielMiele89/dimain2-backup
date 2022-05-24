CREATE TABLE [InsightArchive].[AgeGroupCheck] (
    [cinid]       INT          NOT NULL,
    [fanid]       INT          NOT NULL,
    [hdi_ageband] VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([cinid] ASC) WITH (FILLFACTOR = 90)
);

