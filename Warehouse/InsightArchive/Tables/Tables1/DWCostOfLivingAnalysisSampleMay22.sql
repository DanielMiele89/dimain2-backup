CREATE TABLE [InsightArchive].[DWCostOfLivingAnalysisSampleMay22] (
    [CINID]                     INT            NOT NULL,
    [FanID]                     INT            NOT NULL,
    [CAMEO_CODE_GROUP]          VARCHAR (50)   NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NOT NULL,
    [CAMEO_CODE]                VARCHAR (50)   NULL,
    [CAMEO_CODE_Category]       NVARCHAR (255) NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [CurrentAge]                INT            NULL,
    [EnergyBillChange]          VARCHAR (13)   NULL,
    [LifestageSegment]          VARCHAR (14)   NOT NULL
);

