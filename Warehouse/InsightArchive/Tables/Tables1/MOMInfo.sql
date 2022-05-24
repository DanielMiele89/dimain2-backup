CREATE TABLE [InsightArchive].[MOMInfo] (
    [ConsumerCombinationID] INT          NOT NULL,
    [Acquirer]              VARCHAR (50) NOT NULL,
    [Spend]                 MONEY        NULL,
    [TransactedOnDate]      BIT          NULL,
    [IsReward]              BIT          DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

