CREATE TABLE [InsightArchive].[MasterList_Reintroduction_Dates] (
    [FanID]              INT  NOT NULL,
    [ReintroductionDate] DATE NULL
);


GO
CREATE CLUSTERED INDEX [cix_MasterList_Reintroduction_Dates_FanID]
    ON [InsightArchive].[MasterList_Reintroduction_Dates]([FanID] ASC);

