CREATE TABLE [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304] (
    [MatchedOn] VARCHAR (26) NOT NULL,
    [FanID]     INT          NOT NULL
);




GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304]([FanID] ASC);


GO
GRANT VIEW DEFINITION
    ON OBJECT::[InsightArchive].[MorrisonsReward_MatchedCustomers_20190304] TO [New_PIIRemoved]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[InsightArchive].[MorrisonsReward_MatchedCustomers_20190304] TO [New_PIIRemoved]
    AS [dbo];

