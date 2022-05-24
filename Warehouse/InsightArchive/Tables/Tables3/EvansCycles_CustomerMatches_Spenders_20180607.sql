CREATE TABLE [InsightArchive].[EvansCycles_CustomerMatches_Spenders_20180607] (
    [FanID] INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_EvansCycles_CustomerMatches_FanID]
    ON [InsightArchive].[EvansCycles_CustomerMatches_Spenders_20180607]([FanID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[EvansCycles_CustomerMatches_Spenders_20180607] TO [New_PIIRemoved]
    AS [dbo];

