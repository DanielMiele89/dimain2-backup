CREATE TABLE [MI].[BulkForecast_NonSpenderCINID] (
    [ID]             INT   IDENTITY (1, 1) NOT NULL,
    [CINID]          INT   NOT NULL,
    [BrandID]        INT   NOT NULL,
    [isLapsed]       BIT   NOT NULL,
    [SpendThreshold] MONEY NOT NULL,
    CONSTRAINT [PK_BulkForecast_NonSpenderCINID] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_NCL_BulkForecast_BrandID]
    ON [MI].[BulkForecast_NonSpenderCINID]([BrandID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_NCL_BulkForecast_CINID]
    ON [MI].[BulkForecast_NonSpenderCINID]([CINID] ASC);

