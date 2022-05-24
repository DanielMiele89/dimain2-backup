CREATE TABLE [InsightArchive].[SubjectLineTestingJuly2019_ExecutionResults] (
    [fanid]     INT          NULL,
    [GroupType] VARCHAR (30) NULL,
    [TestName]  VARCHAR (50) NULL,
    [RunDate]   DATE         NULL
);


GO
CREATE CLUSTERED INDEX [INX]
    ON [InsightArchive].[SubjectLineTestingJuly2019_ExecutionResults]([fanid] ASC);

