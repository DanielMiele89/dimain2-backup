CREATE TABLE [MI].[BulkForecast_Results] (
    [ID]                 INT             IDENTITY (1, 1) NOT NULL,
    [BrandID]            INT             NOT NULL,
    [CustomerCount]      INT             NOT NULL,
    [TotalActivatedBase] INT             NOT NULL,
    [Split]              NVARCHAR (1000) NOT NULL,
    [SpendThreshold]     MONEY           NOT NULL,
    CONSTRAINT [PK_BulkForecast_Results] PRIMARY KEY CLUSTERED ([ID] ASC)
);

