CREATE TABLE [InsightArchive].[Halfords_Roc_Phase1_EveryOneElseGroups] (
    [WaveID] INT NOT NULL,
    [FanID]  INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [i_Halfords_Roc_Phase1_EveryOneElseGroups_FanID]
    ON [InsightArchive].[Halfords_Roc_Phase1_EveryOneElseGroups]([FanID] ASC);


GO
CREATE CLUSTERED INDEX [i_Halfords_Roc_Phase1_EveryOneElseGroups_WaveID]
    ON [InsightArchive].[Halfords_Roc_Phase1_EveryOneElseGroups]([WaveID] ASC);

