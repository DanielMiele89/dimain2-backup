CREATE TABLE [Relational].[GeoDemographicHeatMap_HeatMapID] (
    [HeatMapID]        INT           IDENTITY (1, 1) NOT NULL,
    [Gender]           CHAR (1)      NOT NULL,
    [AgeGroup]         VARCHAR (100) NOT NULL,
    [CAMEO_CODE_GRP]   VARCHAR (200) NOT NULL,
    [DriveTimeBand]    VARCHAR (50)  NOT NULL,
    [MinAge]           SMALLINT      NULL,
    [MaxAge]           SMALLINT      NULL,
    [CAMEO_CODE_GROUP] VARCHAR (2)   NULL,
    [SocialClass]      VARCHAR (2)   NULL,
    [DriveTimeBandID]  SMALLINT      NULL,
    PRIMARY KEY CLUSTERED ([HeatMapID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_Gender]
    ON [Relational].[GeoDemographicHeatMap_HeatMapID]([Gender] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_AgeGroup]
    ON [Relational].[GeoDemographicHeatMap_HeatMapID]([AgeGroup] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CCG]
    ON [Relational].[GeoDemographicHeatMap_HeatMapID]([CAMEO_CODE_GRP] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_DTB]
    ON [Relational].[GeoDemographicHeatMap_HeatMapID]([DriveTimeBand] ASC);

