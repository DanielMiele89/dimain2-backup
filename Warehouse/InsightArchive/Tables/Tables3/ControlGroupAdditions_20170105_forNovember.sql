CREATE TABLE [InsightArchive].[ControlGroupAdditions_20170105_forNovember] (
    [ControlgroupID] INT NULL,
    [FanID]          INT NULL
);


GO
CREATE CLUSTERED INDEX [i_ControlGroupAdditions_20170105_forNovember_CGID]
    ON [InsightArchive].[ControlGroupAdditions_20170105_forNovember]([ControlgroupID] ASC);

