CREATE TABLE [InsightArchive].[GrouponUnmatchedFansAggregated_20180110] (
    [TotalAmount] MONEY          NULL,
    [NoOfTrans]   INT            NULL,
    [FanID]       INT            NOT NULL,
    [Email]       VARCHAR (100)  NULL,
    [HashedEmail] NVARCHAR (MAX) NULL
);

