CREATE TABLE [MI].[BulkForecast_Options] (
    [ID]             INT   IDENTITY (1, 1) NOT NULL,
    [BrandID]        INT   NULL,
    [CompetitorID]   INT   NULL,
    [SectorID]       INT   NULL,
    [isLapsed]       BIT   NULL,
    [SpendThreshold] MONEY DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_BulkForecast_Options] PRIMARY KEY CLUSTERED ([ID] ASC)
);

