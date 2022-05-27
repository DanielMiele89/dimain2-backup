CREATE TABLE [Staging].[GeodemographicHeatMap_FanHeatMapID] (
    [FanHeatMapID] INT IDENTITY (1, 1) NOT NULL,
    [FanID]        INT NULL,
    [PartnerID]    INT NULL,
    [HeatMapID]    INT NULL,
    PRIMARY KEY CLUSTERED ([FanHeatMapID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Staging].[GeodemographicHeatMap_FanHeatMapID]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_PartnerID]
    ON [Staging].[GeodemographicHeatMap_FanHeatMapID]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_HeatMapID]
    ON [Staging].[GeodemographicHeatMap_FanHeatMapID]([HeatMapID] ASC);

