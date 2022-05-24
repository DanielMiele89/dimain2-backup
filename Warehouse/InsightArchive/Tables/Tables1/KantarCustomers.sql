CREATE TABLE [InsightArchive].[KantarCustomers] (
    [GroupType] VARCHAR (7) NOT NULL,
    [CINID]     INT         NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_CINID]
    ON [InsightArchive].[KantarCustomers]([CINID] ASC);

