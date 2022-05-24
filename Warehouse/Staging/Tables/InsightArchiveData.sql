CREATE TABLE [Staging].[InsightArchiveData] (
    [ID]     INT      IDENTITY (1, 1) NOT NULL,
    [FANID]  INT      NOT NULL,
    [Date]   DATETIME NULL,
    [TypeID] INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

