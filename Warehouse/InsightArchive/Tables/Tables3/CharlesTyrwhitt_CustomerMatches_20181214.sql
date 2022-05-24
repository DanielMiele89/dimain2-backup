CREATE TABLE [InsightArchive].[CharlesTyrwhitt_CustomerMatches_20181214] (
    [FanID] INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_Fan]
    ON [InsightArchive].[CharlesTyrwhitt_CustomerMatches_20181214]([FanID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[CharlesTyrwhitt_CustomerMatches_20181214] TO [New_PIIRemoved]
    AS [dbo];

