CREATE TABLE [InsightArchive].[EvansCycles_CustomerMatches_20170419] (
    [FanID] INT NOT NULL
);




GO
CREATE CLUSTERED INDEX [cix_EvansCycles_CustomerMatches_20170419_FanID]
    ON [InsightArchive].[EvansCycles_CustomerMatches_20170419]([FanID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[EvansCycles_CustomerMatches_20170419] TO [New_PIIRemoved]
    AS [dbo];

