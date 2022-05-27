CREATE TABLE [InsightArchive].[propensitycustomer] (
    [CINID]           INT          NOT NULL,
    [FanID]           INT          NOT NULL,
    [Age]             TINYINT      NOT NULL,
    [Gender]          VARCHAR (1)  NOT NULL,
    [region]          VARCHAR (20) NOT NULL,
    [CameoGroup]      VARCHAR (5)  NOT NULL,
    [age_group]       VARCHAR (50) NULL,
    [cameo_txt]       VARCHAR (50) NULL,
    [Heatmap_Index]   INT          NULL,
    [age_group_ID]    TINYINT      NULL,
    [Drive_time_Mins] FLOAT (53)   NULL,
    PRIMARY KEY CLUSTERED ([CINID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

