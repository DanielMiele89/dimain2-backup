CREATE TABLE [InsightArchive].[Groupon_CustomerMatches_20180117] (
    [FanID] INT NOT NULL
);




GO
CREATE CLUSTERED INDEX [idx_FanID]
    ON [InsightArchive].[Groupon_CustomerMatches_20180117]([FanID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[Groupon_CustomerMatches_20180117] TO [New_PIIRemoved]
    AS [dbo];

