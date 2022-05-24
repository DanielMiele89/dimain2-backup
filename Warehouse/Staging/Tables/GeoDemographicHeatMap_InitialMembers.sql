CREATE TABLE [Staging].[GeoDemographicHeatMap_InitialMembers] (
    [InitialMembersID]     INT IDENTITY (1, 1) NOT NULL,
    [FanID]                INT NOT NULL,
    [PartnerID]            INT NOT NULL,
    [ResponseIndexBand_ID] INT NOT NULL,
    [HeatMapID]            INT NULL,
    PRIMARY KEY CLUSTERED ([InitialMembersID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Staging].[GeoDemographicHeatMap_InitialMembers]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_PID]
    ON [Staging].[GeoDemographicHeatMap_InitialMembers]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_RID]
    ON [Staging].[GeoDemographicHeatMap_InitialMembers]([ResponseIndexBand_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_HID]
    ON [Staging].[GeoDemographicHeatMap_InitialMembers]([HeatMapID] ASC);

