CREATE TABLE [InsightArchive].[ActiveCustomers] (
    [CINID]              INT          NOT NULL,
    [Segment]            VARCHAR (7)  NOT NULL,
    [ShareOfWalletGroup] VARCHAR (22) NOT NULL,
    [TransRank]          BIGINT       NULL
);


GO
CREATE CLUSTERED INDEX [cx_Stuff]
    ON [InsightArchive].[ActiveCustomers]([CINID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

