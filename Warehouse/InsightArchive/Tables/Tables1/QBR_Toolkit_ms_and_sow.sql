CREATE TABLE [InsightArchive].[QBR_Toolkit_ms_and_sow] (
    [report_type]               VARCHAR (15)   NOT NULL,
    [report_date]               DATETIME       NOT NULL,
    [main_brand]                VARCHAR (50)   NULL,
    [sow_brand]                 VARCHAR (50)   NULL,
    [period]                    VARCHAR (8)    NULL,
    [period_start_date]         DATE           NULL,
    [period_end_date]           DATE           NULL,
    [BrandName]                 VARCHAR (50)   NOT NULL,
    [AgeCurrentBandText]        VARCHAR (10)   NULL,
    [Region]                    VARCHAR (30)   NULL,
    [Gender]                    CHAR (1)       NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NOT NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [isonline]                  INT            NULL,
    [SALES]                     MONEY          NULL,
    [TRANSACTIONS]              INT            NULL,
    [CUSTOMERS]                 INT            NULL
);

