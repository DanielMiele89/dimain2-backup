CREATE TABLE [InsightArchive].[MorrisonsLaunch_MorrisonsRewardMatchedCustomers_20180530] (
    [FanID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [IDX_FanID]
    ON [InsightArchive].[MorrisonsLaunch_MorrisonsRewardMatchedCustomers_20180530]([FanID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[MorrisonsLaunch_MorrisonsRewardMatchedCustomers_20180530] TO [New_PIIRemoved]
    AS [dbo];

