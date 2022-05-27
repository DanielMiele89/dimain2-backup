CREATE TABLE [MI].[BulkForecast_CompetitorCC] (
    [ID]                    INT IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT NOT NULL,
    [CompetitorBrandID]     INT NOT NULL,
    [Brand]                 INT NOT NULL,
    CONSTRAINT [PK_BulkForecast_CompetitorCC] PRIMARY KEY CLUSTERED ([ID] ASC)
);

