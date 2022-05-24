CREATE TABLE [InsightArchive].[MarketableNotBeingEmailed_20161109] (
    [FanID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [INX_MarketableNotBeingEmailed]
    ON [InsightArchive].[MarketableNotBeingEmailed_20161109]([FanID] ASC);

