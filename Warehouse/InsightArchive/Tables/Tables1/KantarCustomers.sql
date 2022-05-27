CREATE TABLE [InsightArchive].[KantarCustomers] (
    [GroupType] VARCHAR (7) NOT NULL,
    [CINID]     INT         NOT NULL
);




GO
CREATE CLUSTERED INDEX [cix_CINID]
    ON [InsightArchive].[KantarCustomers]([CINID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[KantarCustomers] TO [New_PIIRemoved]
    AS [dbo];

