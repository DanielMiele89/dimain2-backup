CREATE TABLE [InsightArchive].[uDataSet_1702] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [TranYear]      INT          NULL,
    [FanID]         INT          NULL,
    [PublisherName] VARCHAR (30) NULL,
    [Cashback]      FLOAT (53)   NULL,
    [Spender]       INT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

