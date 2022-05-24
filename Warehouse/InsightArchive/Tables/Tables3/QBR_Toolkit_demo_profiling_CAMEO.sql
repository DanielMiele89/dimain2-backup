CREATE TABLE [InsightArchive].[QBR_Toolkit_demo_profiling_CAMEO] (
    [main_brand]                VARCHAR (50)   NULL,
    [report_date]               DATETIME       NOT NULL,
    [BrandName]                 VARCHAR (50)   NOT NULL,
    [period_start_date]         DATE           NULL,
    [period_end_date]           DATE           NULL,
    [PERIOD]                    VARCHAR (8)    NULL,
    [Gender]                    CHAR (1)       NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NOT NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [SPEND]                     MONEY          NULL,
    [TRANSACTIONS]              INT            NULL,
    [CUSTOMERS]                 INT            NULL,
    [TOTAL_COUNT]               INT            NULL,
    [Isonline]                  INT            NULL
);

