CREATE TABLE [Stratification].[CBPCardUsageUplift_Cohort_FanID] (
    [fanid]  INT          NOT NULL,
    [Cohort] VARCHAR (50) NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND_COHORT]
    ON [Stratification].[CBPCardUsageUplift_Cohort_FanID]([fanid] ASC);

