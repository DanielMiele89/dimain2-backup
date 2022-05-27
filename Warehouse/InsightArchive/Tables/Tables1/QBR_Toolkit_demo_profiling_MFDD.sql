CREATE TABLE [InsightArchive].[QBR_Toolkit_demo_profiling_MFDD] (
    [main_brand]                VARCHAR (50)   NULL,
    [report_date]               DATE           NULL,
    [BrandName]                 VARCHAR (50)   NOT NULL,
    [PERIOD]                    VARCHAR (8)    NULL,
    [period_start_date]         DATE           NULL,
    [period_end_date]           DATE           NULL,
    [AgeCurrentBandText]        VARCHAR (10)   NULL,
    [Gender]                    CHAR (1)       NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NOT NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [Region]                    VARCHAR (30)   NULL,
    [customers]                 INT            NULL,
    [total_count]               INT            NULL
);

