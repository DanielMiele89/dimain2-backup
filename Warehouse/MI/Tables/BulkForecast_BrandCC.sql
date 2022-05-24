CREATE TABLE [MI].[BulkForecast_BrandCC] (
    [ConsumerCombinationID] INT NOT NULL,
    [BrandID]               INT NOT NULL,
    CONSTRAINT [PK_BulkForecast_BrandCC] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_NCL_BrandCC_BrandID]
    ON [MI].[BulkForecast_BrandCC]([BrandID] ASC);

