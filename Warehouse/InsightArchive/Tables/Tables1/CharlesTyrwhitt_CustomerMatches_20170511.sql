CREATE TABLE [InsightArchive].[CharlesTyrwhitt_CustomerMatches_20170511] (
    [FanID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_CharlesTyrwhitt_CustomerMatches_20170511_FanID]
    ON [InsightArchive].[CharlesTyrwhitt_CustomerMatches_20170511]([FanID] ASC);

