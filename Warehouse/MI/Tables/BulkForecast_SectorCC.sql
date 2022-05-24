CREATE TABLE [MI].[BulkForecast_SectorCC] (
    [ConsumerCombinationID] INT NOT NULL,
    [BrandID]               INT NOT NULL,
    [SectorID]              INT NOT NULL,
    CONSTRAINT [PK_BulkForecast_SectorCC] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_NCL_SectorCC_BrandID]
    ON [MI].[BulkForecast_SectorCC]([BrandID] ASC);

