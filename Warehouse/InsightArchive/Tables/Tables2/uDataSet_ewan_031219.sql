CREATE TABLE [InsightArchive].[uDataSet_ewan_031219] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [TranYear]      INT          NOT NULL,
    [FanID]         INT          NOT NULL,
    [PublisherName] VARCHAR (50) NOT NULL,
    [Cashback]      FLOAT (53)   NOT NULL,
    [Spender]       INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

