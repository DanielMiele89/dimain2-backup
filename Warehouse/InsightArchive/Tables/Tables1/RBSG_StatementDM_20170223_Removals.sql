CREATE TABLE [InsightArchive].[RBSG_StatementDM_20170223_Removals] (
    [RewardCustomerID] INT NOT NULL
);




GO
DENY SELECT
    ON OBJECT::[InsightArchive].[RBSG_StatementDM_20170223_Removals] TO [New_PIIRemoved]
    AS [dbo];

