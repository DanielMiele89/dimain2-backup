CREATE TABLE [InsightArchive].[FanExclude] (
    [Fanid]        INT          NOT NULL,
    [Segment]      VARCHAR (50) NULL,
    [Spend]        VARCHAR (50) NULL,
    [Transactions] VARCHAR (50) NULL,
    PRIMARY KEY CLUSTERED ([Fanid] ASC)
);

