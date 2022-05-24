CREATE TABLE [MI].[BulkForecast_StagingCINList] (
    [ID]       INT IDENTITY (1, 1) NOT NULL,
    [CINID]    INT NOT NULL,
    [BrandID]  INT NOT NULL,
    [isLapsed] BIT NULL,
    CONSTRAINT [PK_BulkForecast_StagingCINList] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_NCL_CINList_CINID]
    ON [MI].[BulkForecast_StagingCINList]([CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_NCL_CINList_BrandID]
    ON [MI].[BulkForecast_StagingCINList]([BrandID] ASC);

