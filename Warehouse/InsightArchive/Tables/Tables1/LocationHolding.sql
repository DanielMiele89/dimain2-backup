CREATE TABLE [InsightArchive].[LocationHolding] (
    [ID]                    INT IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT NOT NULL,
    [locationid]            INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

