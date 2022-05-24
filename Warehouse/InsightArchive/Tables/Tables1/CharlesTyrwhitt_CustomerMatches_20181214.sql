CREATE TABLE [InsightArchive].[CharlesTyrwhitt_CustomerMatches_20181214] (
    [FanID] INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_Fan]
    ON [InsightArchive].[CharlesTyrwhitt_CustomerMatches_20181214]([FanID] ASC);

