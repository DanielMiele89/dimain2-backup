CREATE TABLE [InsightArchive].[CharlesTyrwhitt_CustomerMatches_20170511] (
    [FanID] INT NOT NULL
);




GO
CREATE CLUSTERED INDEX [cix_CharlesTyrwhitt_CustomerMatches_20170511_FanID]
    ON [InsightArchive].[CharlesTyrwhitt_CustomerMatches_20170511]([FanID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[CharlesTyrwhitt_CustomerMatches_20170511] TO [New_PIIRemoved]
    AS [dbo];

